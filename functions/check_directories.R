#' check_directories.R
#' 
#' This code confirm directory structures
#' 
TFindex <- match("ScrapedFiles", list.files())
if( is.na(TFindex) ){
    dir.create("ScrapedFiles")
}