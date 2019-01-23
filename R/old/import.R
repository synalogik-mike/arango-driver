library(jsonlite)

importJson <- function(jsonPath){
  tweets <- list()
  files <- list.files(path=jsonPath, full.names=T)
  processed <-0

  for(file in files){

    processed <- processed + 1

    tweet = tryCatch({
      jsonlite::fromJSON(file)
    }, warning = function(w) {
      print(paste0("Cannot import ",file,sep=""))
      NA
    }, error = function(e) {
      print(paste0("Cannot import ",file,sep=""))
      NA
    })

    if(!is.na(tweet)){
      if(processed %% 1000 == 0){
        print(paste0("Processed ",processed,sep=""))
      }

      tweets[[as.character(tweet$id)]] <- tweet
    }
  }

  return(tweets)
}
