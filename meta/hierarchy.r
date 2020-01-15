library('tidyverse')
library('RPostgreSQL')
drv = dbDriver("PostgreSQL")
con = dbConnect(drv, dbname="bikemap",user="nate",password='mink')
# get the data
x = as_tibble( dbGetQuery(
  con,
  paste(
    "SELECT f, r, ST_Length(edge) AS length, name", 
    "FROM street_edges",
    "WHERE render AND",
    "ST_Intersects(",
  	  "edge,",
		  "(SELECT way FROM context_polygon WHERE name='Old Toronto')",
	  ");"
  )
) )
# density plot of edge counts
x %>%
  mutate(
    y = pmax(f,r),
    w = length / sum(length)
  ) %>%
  ggplot() + 
    geom_density( aes( x=y, weight=w ) ) + 
    geom_vline( aes( xintercept=30 ),color='red' )