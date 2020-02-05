library('tidyverse')
library('RPostgreSQL')
drv = dbDriver("PostgreSQL")
con = dbConnect(drv, dbname="bikemap",user="nate",password='mink')

cutpoints = c(-1,30,110,250,999)

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


x %>%
  mutate( bin = cut(pmax(f,r),cutpoints,labels=1:4) ) %>%
  group_by(bin) %>%
  summarize( sum = sum(length) ) %>%
  ggplot() + 
    geom_col( aes(x=bin,y=sum) ) + 
    theme_minimal()


# density plot of edge counts
x %>%
  mutate(
    y = pmax(f,r),
    w = length / sum(length)
  ) %>%
  ggplot() + 
    geom_vline( xintercept=c(40,100,200) ,color='red' ) + 
    geom_density( aes( x=y, weight=w ) ) + 
    theme_minimal()
