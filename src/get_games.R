library(baseballr)
library(dplyr)
library(lubridate)
#### get games for players ####

# load data
pitchers <- read.csv("data/players/players_cleaned.csv")

# add season column
pitchers <- pitchers %>%
  mutate(season_traded = year(date)) %>%
  relocate(season_traded)

# get list of games for each player from fangraphs
for(i in 1:nrow(pitchers)){
  # fangraphs id
  id = pitchers$fangraphs_id[i]
  season = pitchers$season_traded[i]
  # add games
  games <- pitcher_game_logs_fg(playerid = id, year = season)
  # add id columns
  games <- cbind(games, 
                 data.frame(mlbam_id = pitchers$mlbam_id[i],
                            retrosheet_id = pitchers$retrosheet_id[i],
                            bbref_id = pitchers$bbref_id[i]))
  if(i == 1){
    games_all <- games
  } else {
    games_all <- rbind(games_all, games, fill=TRUE)
  }
}

# get pitcher-catcher data for each game
#### this is definitely not the most efficient way to do this, clean this up with above ####
# filter games to player
pitcher_summaries <- games_all %>%
  # filter(PlayerName == player) %>%
  group_by(PlayerName, season) %>%
  # get date range
  summarise(min_date = min(Date), max_date = max(Date),
            # get ids
            mlbam_id = mlbam_id[1], retrosheet_id = retrosheet_id[1], bbref_id = bbref_id[1])

# loop through pitchers to get all pitcher data
for(pitcher in 1:nrow(pitcher_summaries)){
  
  # print progress
  print(paste("Getting data for", pitcher_summaries$PlayerName[pitcher]))
  print(paste(pitcher, "of", nrow(pitcher_summaries)))
  
  # get pitcher data
  pitcher_data <- statcast_search_pitchers(start_date = pitcher_summaries$min_date[pitcher], 
                                           end_date = pitcher_summaries$max_date[pitcher], 
                                           pitcherid = pitcher_summaries$mlbam_id[pitcher])
  
  # export as csv
  write.csv(pitcher_data, paste("data/players/game_logs/", pitcher_summaries$PlayerName[pitcher], ".csv", sep=""))
}

# combine all pitcher data


