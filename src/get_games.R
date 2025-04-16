library(baseballr)
library(dplyr) # data manipulation
library(tidyr) # pivot wider
library(lubridate) # handle dates
library(data.table) # reading in csvs faster
source("src/format_data.R") # if needing to load in individual game data
#### get games for players ####

# load data
pitchers <- data.table::fread("data/players/players_cleaned.csv")
game_summaries <- data.table::fread("data/players/game_summaries.csv")[, -1]
# pitch_level <- read_data("data/players/game_logs/")
pitch_level <- data.table::fread("data/players/pitches.csv")

#### Cleaning Up Data ####
# if necessary, clean up formatting
pitch_level <- pitch_level %>%
  # drop any duplicates
  distinct() %>%
  mutate(
    # make sure date is in correct format
    game_date = as.Date(game_date),
    # add season column
    season = year(game_date), .before = game_date)

# export 
# write.csv(pitch_level[,-1], "data/players/pitches.csv", row.names = FALSE)

# add season column to pitchers
pitchers <- pitchers %>%
  mutate(season = year(date), .before = date) 


#### How to Get Game Logs ####
# get game logs for each player from fangraphs
get_all_game_logs <- function(pitcher_df){
  
  pitchers <- pitcher_df
  
  # iterate through all pitchers
  for(i in 1:nrow(pitchers)){
    # check if df has fangraphs id
    if(is.na(pitchers$fangraphs_id)){
      print("Column 'fangraphs_id' does not exist in dataframe")
    } 
    # if present, get game logs
    else{
      id = pitchers$fangraphs_id[i]
      # skip if individual id is missing
      if(is.na(id)){
        next
      } else {
        season = pitchers$season_traded[i]
        
        # print message
        print(paste0("Fetching Player: ", pitchers$player[i]), "of ", nrow(pitchers), 
              "in season: ", season)
        
        # get games
        games <- pitcher_game_logs_fg(playerid = id, year = season)
        # add id columns
        games <- cbind(games, 
                       data.frame(mlbam_id = pitchers$mlbam_id[i],
                                  retrosheet_id = pitchers$retrosheet_id[i],
                                  bbref_id = pitchers$bbref_id[i]))
        
        # initialize game summaries
        if(is.NULL(game_summaries)){
          game_summaries <- games
        } 
        # append results
        else {
          game_summaries <- rbind(game_summaries, games, fill=TRUE)
        }
      }
    }
    # return all summaries
    return(game_summaries)
    }
    
}
game_summaries <- get_all_game_logs(pitchers)

# write out game logs
# write.csv(game_summaries, "data/players/game_logs/game_summaries.csv")

#### Get Pitch Level Data ####
## (this is definitely not the most efficient way to do this, clean this up future me pls :D) ##
# write out to csv all individual pitchers pitch level data for all games in the span #
get_pitch_level_data_individual <- function(df){
  game_summaries <- df
  # get range of games for each pitcher
  pitcher_summaries <- game_summaries %>%
    group_by(PlayerName, season) %>%
    # get date range
    summarise(min_date = min(Date), max_date = max(Date),
              # get ids
              mlbam_id = mlbam_id[1], retrosheet_id = retrosheet_id[1], bbref_id = bbref_id[1])
  
  # loop through pitchers to get all pitcher data
  for(pitcher in 1:nrow(pitcher_summaries)){
    # print progress
    print(paste(pitcher, "of", nrow(pitcher_summaries)))
    # get pitcher data
    pitcher_data <- statcast_search_pitchers(start_date = pitcher_summaries$min_date[pitcher], 
                                             end_date = pitcher_summaries$max_date[pitcher], 
                                             pitcherid = pitcher_summaries$mlbam_id[pitcher])
    # export as csv
    write.csv(pitcher_data, 
              paste("data/players/game_logs/", 
                    pitcher_summaries$PlayerName[pitcher], "_",
                    pitcher_summaries$season[pitcher],
                    ".csv", 
                    sep=""))
  }
}

# get_pitch_level_data_individual(game_summaries)
# pitch_level <- read_data("data/players/game_logs/")

# group into pre-trade and post trade data
# get count of all pitches
pitch_counts <- pitch_level %>%
  count(pitch_type, name = "Freq") %>%
  arrange(desc(Freq))
pitch_counts

# get aggregate data for each pitcher
pitch_usage <- pitch_level %>% 
  # get the trade date for each pitcher
  left_join(
    pitchers %>% 
      rename(trade_date = date) %>%
      select(trade_date, mlbam_id, season), 
    by = c("pitcher"="mlbam_id", 
           "season"="season"),
    relationship = "many-to-many") %>%
  # create columns to group by trade status and pitch type
  mutate(
    # create column for trade status
    trade_status = case_when(game_date >= trade_date ~ "post_trade",
                             game_date < trade_date ~ "pre_trade"), .before = game_date) %>%
  # filter out NA pitch types
  filter(!is.na(pitch_type) & pitch_type != "") %>%
  # Convert pitch types into wide format
  mutate(pitches_thrown = 1) %>%
  pivot_wider(
    names_from = pitch_type, 
    values_from = pitches_thrown, 
    values_fill = list(pitches_thrown = 0)
  ) %>%
  # group pitcher stats by trade status
  group_by(player_name, trade_status, pitcher) %>%
  # get summary of pitcher performance
  summarize(
    n_pitches = n(),
    # get raw counts of pitches
    across(CU:SV, sum, .names = "count_{.col}"),
    # get percentage of usage
    across(starts_with("count_"), ~ .x / n_pitches, .names = "pct_{.col}")
  )

# don't consider SV, PO since they're low counts
pitch_usage <- pitch_usage %>%
  select(-c(count_SV, count_PO, 
            pct_count_SV, pct_count_PO))

# export if necessary
# write.csv(pitch_usage, "data/players/pitch_usage.csv")

#### add trade status to game summaries ####
# function to add trade status to game summaries
process_trade_status <- function(pitch_level_data, pitchers_df) {
  all_pitches <- pitch_level_data
  pitchers <- pitchers_df
  all_pitches <- all_pitches %>%
    # Join trade date by matching season and pitcher ID
    left_join(
      pitchers %>%
        rename(trade_date = date) %>%
        select(season, trade_date, mlbam_id),
      by = c("season", "pitcher" = "mlbam_id"),
      relationship = "many-to-many"
    ) %>%
    # Assign trade status
    mutate(
      trade_status = case_when(
        game_date >= trade_date ~ "post_trade",
        game_date < trade_date ~ "pre_trade"
      ),
      .before = game_date
    )
  return(all_pitches)
}

all_pitches <- process_trade_status(pitch_level, pitchers)

# Look at the number of pitches for each player before and after trades
all_pitches %>%
  group_by(trade_status, trade_date, player_name) %>%
  summarize(n_pitches = n()) %>%
  View()


# get trade dates for each game
all_trade_dates <- all_pitches %>%
  select(trade_status, pitcher, game_date, season, player_name) %>%
  group_by(pitcher, game_date, season) %>%
  summarize(trade_status = trade_status[1],
            game_date = game_date[1],
            mlbam_id = pitcher[1]) %>%
  left_join(pitchers %>%
              select(mlbam_id, fangraphs_id),
            by="mlbam_id",
            relationship = "many-to-many")

# link trade status from all trade dates with game summaries
game_summaries <- game_summaries %>%
  mutate(Date = as.Date(Date)) %>%
  left_join(all_trade_dates %>%
              select(-c(mlbam_id, pitcher)),
            by = c("playerid"="fangraphs_id", "Date"="game_date", "season"="season"), 
            relationship = "many-to-many") %>%
  relocate(trade_status, .after = Date)

# export game summaries with trade status
# write.csv(game_summaries, "data/players/game_summaries_trades.csv", row.names = FALSE)

game_summaries_trades <- game_summaries %>%
  # filter out any NA trade status
  filter(!is.na(trade_status))

# get average innings pitched before and after trade
pitching_avg <- game_summaries_trades %>%
  # change season var later
  group_by(season, trade_status, PlayerName) %>%
  summarize(avg_IP = mean(IP, na.rm = TRUE),
            n_IP = sum(IP, na.rm = TRUE),
            gs_pct = mean(GS, na.rm = TRUE),
            sv_pct = mean(SV, na.rm = TRUE),
            hld_pct = mean(HLD, na.rm = TRUE),
            tbf_avg = mean(TBF, na.rm = TRUE),
            h_avg = mean(H, na.rm = TRUE),
            er_avg = mean(ER, na.rm = TRUE),
            hr_avg = mean(HR, na.rm = TRUE),
            bb_avg = mean(BB, na.rm = TRUE),
            hbp_avg = mean(HBP, na.rm = TRUE),
            wp_avg = mean(WP, na.rm = TRUE),
            bk_avg = mean(BK, na.rm = TRUE),
            k_per_9 = sum(SO, na.rm = TRUE) / sum(IP, na.rm = TRUE) * 9,
            bb_per9_avg = sum(BB, na.rm = TRUE) / sum(IP, na.rm = TRUE) * 9,
            whip = (sum(BB, na.rm = TRUE)+sum(H, na.rm = TRUE)) / sum(IP, na.rm = TRUE) * 9,
            babip_est = (sum(H, na.rm = TRUE) - sum(HR, na.rm = TRUE)) / (sum(TBF, na.rm = TRUE) - sum(SO, na.rm = TRUE) - sum(HR, na.rm = TRUE) - sum(BB, na.rm = TRUE) - sum(HBP, na.rm = TRUE)),
            pitches_avg = mean(Pitches, na.rm = TRUE))

# export if necessary
write.csv(pitching_avg, "data/players/pitching_avg.csv")



