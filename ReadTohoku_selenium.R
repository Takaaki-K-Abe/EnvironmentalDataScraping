
system("java -jar selenium.jar &")

rsChr <- RSelenium::remoteDriver(port = 4444L, browserName = "chrome")
rsChr$open()

# suion page at tohoku
dir = "http://tohokubuoynet.myg.affrc.go.jp/Vdata/vdata5.aspx?vid=v15&gid=0"
rsChr$navigate(dir)

# set date and time for scrape
rsChr$refresh()
webElem <- rsChr$findElement(using = "xpath", value ="//*[@id=\"DateSelect\"]")
for(i in 1:10){
  webElem$sendKeysToElement( list(key="backspace") )
}
webElem$sendKeysToElement( list("20211115") )
webElem <- rsChr$findElement(using = "xpath", value ="//*[@id=\"TimeSelect\"]")
webElem$clickElement()
Sys.sleep(0.5)
webElem <- rsChr$findElement(using = "xpath", value ="//*[@id=\"TimeSelect\"]")
webElem$sendKeysToElement( list("23") )

load_shiogama_data <- function(remote, date){
  
  dir = "http://tohokubuoynet.myg.affrc.go.jp/Vdata/vdata5.aspx?vid=v15&gid=0"
  remote$navigate(dir)

  # remote$refresh()
  webElem <- remote$findElement(using = "xpath", value ="//*[@id=\"DateSelect\"]")
  for(i in 1:10){ webElem$sendKeysToElement( list(key="backspace") ) }
  
  webElem$sendKeysToElement(
    list( strftime(date, "%Y%m%d") ) 
  )
  
  # set date
  webElem <- remote$findElement(using = "xpath", value ="//*[@id=\"TimeSelect\"]")
  webElem$clickElement()
  Sys.sleep(0.5)
  # Target data is from 23:00 for the past 24 hours
  webElem <- remote$findElement(using = "xpath", value ="//*[@id=\"TimeSelect\"]")
  webElem$sendKeysToElement( list("23") )
  
  # analyse html
  pagesource <- remote$getPageSource() %>% unlist()
  suion_html <- read_html(pagesource) %>% html_table()
  data <- bind_cols(suion_html[[8]], suion_html[[9]])
  
  timestring <- data[1,] %>% as.character() %>% 
    str_replace_all(pattern = "時", replacement = ":00")
  names(data) <- timestring

  data <- data %>%  select(ends_with(":00")) %>% .[2,] %>% 
    pivot_longer(
      cols = everything(), names_to = "Time", values_to = "Temp"
      ) %>% 
    mutate( Date = date ) %>% 
    select( Date, everything() )
  return(data)
}

load_shiogama_data(rsChr, as.Date("2021/11/15"))

system("kill 5097")
system("ps -A | grep 'java'")
