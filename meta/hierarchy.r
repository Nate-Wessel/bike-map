library('tidyverse')
library('RPostgreSQL')
drv = dbDriver("PostgreSQL")
con = dbConnect(drv, dbname="bikemap",user="nate",password='mink')
# get the data
x = dbGetQuery(con, "SELECT f,r,ST_Length(edge::geography) AS length FROM gta_edges ORDER BY random() LIMIT 500000;")
# density plot of edge counts
x %>% ggplot() + geom_density(aes(x=log(f+r+1),weight=length/sum(length)))
