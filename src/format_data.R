### function to create dataframe with all data ###
read_data <- function(folder_path){
  # iterate through all files in the transactions folder (or whichever folder)
  for(file in 1:length(list.files(folder_path))){
    
    # get name of file
    filename = list.files(folder_path)[file]
    filename = paste0(folder_path, filename) # add path to filename
    
    # read in data
    tmp_data <- read.csv(filename)
    
    # if first file, create dataframe
    if(file == 1){
      data <- tmp_data
    } else {
      # append data
      data <- rbind(data, tmp_data)
    }
  }
  return(data)
}

### test using function ###
# path <- "data/transactions/"
# df <- read_data(path)



