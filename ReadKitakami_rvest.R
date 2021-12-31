#' ReadKitakamiTemp.R
#' ReadKitakamiTemp: `rvest`を用いて、水門水質データベースより北上川の水温情報を取得するコード

library(rvest)
library(tidyverse)
source("functions/check_directories.R")

#' @title read_kanegasaki
#' 
#' 金ヶ崎の水温計測データを取得する関数
#' 開始日から合計7日分の水温データを取得する
#' 
#' @param startDate 開始日
#' @return suiondata 水温情報をまとめたtibble
#' @example suiondata <- read_kanegasaki(startDate)
read_kanegasaki <- function(startDate){

  src_url = "http://www1.river.go.jp/cgi-bin/DspWquaData.exe?KIND=5&ID=402041282204090&"
  beginDate = paste0( "BGNDATE=", strftime(startDate, "%Y%m%d") )
  endDate = paste0( "ENDDATE=", strftime( startDate + 6, "%Y%m%d") )
  suffix = "&KAWABOU=NO"

  # download html data from suimon-suishitsu database
  url <- paste0(src_url, beginDate, "&", endDate, suffix)
  destfile = paste0("html/temporal.html")
  download.file( url, destfile )

  htmlfile <- read_html( destfile )  
  stringlist <- html_elements(htmlfile, "iframe") %>%
    as.character(.)　%>% strsplit(., "\"")

  download_prefix = "http://www1.river.go.jp/"
  table_download_url <- paste0(download_prefix, stringlist[[1]][2])
  destfile = paste0(
    "html/kanegasaki_", strftime(startDate, "%Y%m%d") ,".html"
  )
  download.file(table_download_url, destfile)

  # read html table from a file
  suionlist <- read_html(destfile) %>% html_table()
  suiondata <- suionlist[[2]]

  return(suiondata)
}

# define period for download
stDate <- as.Date("2021/09/10")
endDate <- as.Date("2021/11/20")

stDateArray <- seq(stDate, endDate, by = "7 days")

# read html temp data
datalist <- lapply(stDateArray, read_kanegasaki)
tempdata_kanegasaki <- invoke("rbind", datalist)

names(tempdata_kanegasaki) <- c(
  "date", "time", "position", "temperature",
  "pH", "DO", "douden", "dakudo", "water_level"
  )

tempdata_kanegasaki <- tempdata_kanegasaki %>% 
  mutate( temperature = str_replace(temperature, "欠測", "NA_character_")) %>% 
  mutate( temperature = as.numeric(temperature))
  
write_csv(tempdata_kanegasaki, "ScrapedFiles/kanegasaki_measuredata.csv")
