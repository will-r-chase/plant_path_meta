##***IMPORTANT*** MUST OPEN WITH UTF-8 ENCODING, open script then go file->reopen with encoding->UTF-8 ##
library(XML)
library(stringr)
library(data.table)
library(tidyr)
library(reshape2)
library(ggmap)
library(sf)
library(mapview)
library(pbapply)
library(leaflet)
library(abind)
library(htmltools)
library(purrr)
library(plyr)
library(dplyr)



files<-list.files(getwd(), pattern="*.html")
x<-files[[1]]

#reads html from USDA files and makes list with all data organized in arrays

  #parse html into text and pull out all paragraph tags
  html_doc <- XML::htmlTreeParse(x, useInternalNodes = T)
  html_text <- unlist(xpathApply(html_doc, '//p', xmlValue))
  
  #get basic data
  basic_data <- data.table(html_text[grepl("Distribution:|Substrate:|Disease Note:|Host:", html_text)])
  basic_data <- separate(basic_data, 1, into = c("attribute", "value"), sep = ":")
  #basic_data$value <- gsub(basic_data$value, pattern = "(\\.[^.]*)$", replacement = "")
  basic_data[, value := gsub(basic_data$value, pattern = "(\\.[^.]*)$", replacement = "")]
  
  #get references and associated codes and store in df
  lit <- html_text[which(grepl("Literature database", html_text)) : which(grepl("Specimens database", html_text))]
  lit <- lit[-c(1, length(lit), length(lit)-1)]
  lit <- strsplit(lit, "\\s(?=\\S*$)", perl=T)
  lit_df <- do.call(rbind.data.frame, lit)
  colnames(lit_df) <- c("reference", "code")
  setDT(lit_df)
  #lit_df$code <- gsub("[()]", "", lit_df$code)
  #lit_df$reference <- as.character(lit_df$reference)
  lit_df[, code := gsub("[()]", "", lit_df$code)]
  lit_df[, reference := as.character(lit_df$reference)]
  
  #get nomenclature data and clean up synonyms
  html_text2 <- html_text[-c(1:4)]
  nomenclature <- html_text2[(which(grepl("Nomenclature data", html_text2))) : (which(grepl("Distribution", html_text2)))]
  nomenclature <- nomenclature[-c(length(nomenclature))]
  nomenclature <- gsub(nomenclature, pattern = "Â|â|‰|=|¡", replacement = "")
  nomenclature <- str_trim(nomenclature, side = "both")
  nomenclature <- gsub(nomenclature, pattern = "Nomenclature data for ", replacement = "")
  
  #get location information from html text and remove empty entries
  locations <- html_text2[(which(grepl("Fungus-Host", html_text2))) : which(grepl("Literature database", html_text2))]
  locations <- locations[-c(1, length(locations), length(locations)-1)]
  locations <- locations[-(grep("\r\n\t\t\t", locations))]
  
  locations <- gsub(locations, pattern = "\\(([^\\)]+)\\)", replacement = "")
  locations <- gsub(locations, pattern = "\\*", replacement = "")
  locations <- gsub(locations, pattern = ";\\s", replacement = ",")
  locations <- gsub(locations, pattern = "ontario", replacement = "Ontario")
  locations <- gsub(locations, pattern = "Abyssinics", replacement = "abyssinics")
  locations <- gsub(locations, pattern = "Andreana", replacement = "andreana")
  locations <- gsub(locations, pattern = "Arborescens", replacement = "arborescens")
  locations <- gsub(locations, pattern = "Aristata", replacement = "aristata")
  locations <- gsub(locations, pattern = "Basilaris", replacement = "basilaris")
  locations <- gsub(locations, pattern = "Baumannii", replacement = "baumannii")
  locations <- gsub(locations, pattern = "Berberis Ilicifolia", replacement = "berberis ilicifolia")
  locations <- gsub(locations, pattern = "Briotii", replacement = "briotii")
  locations <- gsub(locations, pattern = "Canaertii", replacement = "canaertii")
  locations <- gsub(locations, pattern = "Chia", replacement = "chia")
  locations <- gsub(locations, pattern = "Cicadellidae", replacement = "cicadellidae")
  locations <- gsub(locations, pattern = "Condensata", replacement = "condensata")
  locations <- gsub(locations, pattern = "Conspicuus", replacement = "conspicuus")
  locations <- gsub(locations, pattern = "Cordyluridae:", replacement = "cordyluridae")
  locations <- gsub(locations, pattern = "Densa", replacement = "densa")
  locations <- gsub(locations, pattern = "Diptera", replacement = "diptera")
  locations <- gsub(locations, pattern = "Dregeanus", replacement = "dregeanus")
  locations <- gsub(locations, pattern = "Elegantissima", replacement = "elegantissima")
  locations <- gsub(locations, pattern = "Glabrata", replacement = "glabrata")
  locations <- gsub(locations, pattern = "Glauca", replacement = "glauca")
  locations <- gsub(locations, pattern = "Globosa", replacement = "globosa")
  locations <- gsub(locations, pattern = "Grandiflora", replacement = "grandiflora")
  locations <- gsub(locations, pattern = "Homoptera", replacement = "homoptera")
  locations <- gsub(locations, pattern = "Hymenoptera", replacement = "hymenoptera")
  locations <- gsub(locations, pattern = "Islands", replacement = "islands")
  locations <- gsub(locations, pattern = "Japonicus:", replacement = "japonicus")
  locations <- gsub(locations, pattern = "Japonicus", replacement = "japonicus")
  locations <- gsub(locations, pattern = "Lalandei", replacement = "lalandei")
  locations <- gsub(locations, pattern = "Leporinum", replacement = "Leporinum")
  locations <- gsub(locations, pattern = "Longipinnatus", replacement = "longipinnatus")
  locations <- gsub(locations, pattern = "Mantica", replacement = "mantica")
  locations <- gsub(locations, pattern = "Pteridophyta", replacement = "pteridophyta")
  locations <- gsub(locations, pattern = "Pubens", replacement = "pubens")
  locations <- gsub(locations, pattern = "Pyramidalis", replacement = "pyramidalis")
  locations <- gsub(locations, pattern = "Recurvifolia", replacement = "recurvifolia")
  locations <- gsub(locations, pattern = "Rotundifolia", replacement = "rotundifolia")
  locations <- gsub(locations, pattern = "Rough", replacement = "rough")
  locations <- gsub(locations, pattern = "Spp", replacement = "spp")
  locations <- gsub(locations, pattern = "Squarrosa :", replacement = "squarrosa")
  locations <- gsub(locations, pattern = "Suffruticosa", replacement = "suffruticosa")
  locations <- gsub(locations, pattern = "Thunbergii", replacement = "thunbergii")
  locations <- gsub(locations, pattern = "Tripartita", replacement = "tripartita")
  locations <- gsub(locations, pattern = "Vittatum", replacement = "vittatum")
  locations <- gsub(locations, pattern = "Perennis", replacement = "perennis")
  locations <- gsub(locations, pattern = "Rica", replacement = "Costa Rica")
  locations <- gsub(locations, pattern = "Costa Costa Rica", replacement = "Costa Rica")
  locations <- gsub(locations, pattern = "USSR", replacement = "Poland")
  locations <- gsub(locations, pattern = "South Africa Unknown", replacement = "South Africa")
  locations <- gsub(locations, pattern = "Czechoslovakia", replacement = "Czech Republic")
  locations <- gsub(locations, pattern = "Dakota", replacement = "North Dakota")
  locations <- gsub(locations, pattern = "Pacific islands", replacement = "Polynesia")
  locations <- gsub(locations, pattern = "Northwestern States", replacement = "Pacific Northwest States")
  locations <- gsub(locations, pattern = "Southwestern States", replacement = "Southwest United States")
  locations <- gsub(locations, pattern = "Tropical America", replacement = "Central America")
  locations <- gsub(locations, pattern = "Jersey", replacement = "New Jersey")
  locations <- gsub(locations, pattern = "New New Jersey", replacement = "New Jersey")
  locations <- gsub(locations, pattern = "Zambia zim", replacement = "Zambia")
  locations <- gsub(locations, pattern = "Gulf states", replacement = "United States Gulf Coast")
  locations <- gsub(locations, pattern = "Java", replacement = "Indonesia Java")
  locations <- gsub(locations, pattern = "Indonesia Indonesia Java", replacement = "Indonesia Java")
  locations <- gsub(locations, pattern = "North North Dakota", replacement = "North Dakota")
  locations <- gsub(locations, pattern = "Congo\\, Democratic Republic of the", replacement = "Congo")
  locations <- gsub(locations, pattern = "Georgia\\, Republic of", replacement = "Republic of Georgia")
  locations <- gsub(locations, pattern = "Christmas Island\\, Territory of", replacement = "Christmas Island")
  locations <- gsub(locations, pattern = "Congo\\, Republic of the", replacement = "Congo")
  
    #get list of hosts
    hosts <- str_extract(locations, ".+?\\s(?=[A-Z])")
    hosts <- gsub(hosts, pattern = ":", replacement = "")
    
    #split locations into separate columns
    locations <- sub(".+?\\s(?=[A-Z])", "\\1", locations, perl = T)
    locations <- strsplit(locations, "\\,(?=[A-Z]+)", perl = T)
    max.length <- max(sapply(locations, length))
    locations_filled <- lapply(locations, function(x) { c(x, rep(NA, max.length-length(x)))})
    locations_df <- do.call(rbind.data.frame,locations_filled)
    setDT(locations_df)
    locations_df[] <- lapply(locations_df, as.character)
    
    #separate literature codes from location data, put into df, and clean up
    lit_codes <- lapply(locations_df, strsplit, "-")
    lit_codes <- lapply(lit_codes, gsub, pattern = "[^0-9 | ^,]", replacement = "")
    lit_codes_df <- do.call(cbind.data.frame,lit_codes)
    lit_codes_df[] <- lapply(lit_codes_df, as.character)
    lit_codes_df[] <- lapply(lit_codes_df, gsub, pattern = ",", replacement = "")
    lit_codes_df[] <- lapply(lit_codes_df, function(x) trimws(x, which = "both"))
    lit_codes_df[] <- lapply(lit_codes_df, gsub, pattern = " ", replacement = ",")
    colnames(lit_codes_df) <- paste0("code", 1:ncol(locations_df))
    
    links <- list()
 
    for(i in 1:ncol(lit_codes_df)){
      links[[i]] <- data.frame(original_code = lit_codes_df[,i], stringsAsFactors = F)
      max_code <- strsplit(links[[i]][,1], ",")
      max_code_length <- max(lengths(max_code))
      links[[i]] <- separate(links[[i]], 1, into = paste("code", 1:max_code_length, sep = "_"), sep = ",", convert = T)
      links[[i]] <- lapply(links[[i]], as.numeric)
      links[[i]][] <- lapply(links[[i]], function(x) refs$link[match(x, refs$code)])
      paste_args <- list("x" = links[[i]], "sep" = "###", "na.rm" = T)
      links[[i]]$new_link <- do.call(paste5, paste_args)
      links[[i]] <- data.frame(i = links[[i]]$new_link, stringsAsFactors = F)
    }
    
    link_df <- bind_cols(links)
    
    dates <- list()
    
    for(i in 1:ncol(lit_codes_df)){
      dates[[i]] <- data.frame(original_code = lit_codes_df[,i], stringsAsFactors = F)
      max_code <- strsplit(dates[[i]][,1], ",")
      max_code_length <- max(lengths(max_code))
      dates[[i]] <- separate(dates[[i]], 1, into = paste("code", 1:max_code_length, sep = "_"), sep = ",", convert = T)
      dates[[i]][] <- lapply(dates[[i]], as.numeric)
      dates[[i]][] <- lapply(dates[[i]], function(x) refs$date[match(x, refs$code)])
      dates[[i]] <- dates[[i]] %>%
        mutate(min=pmap(dates[[i]], min, na.rm = T))
      dates[[i]]$min <- data.frame(date=unlist(dates[[i]]$min))
      dates[[i]] <- data.frame(i = dates[[i]]$min, stringsAsFactors = F)
      is.na(dates[[i]]) <- sapply(dates[[i]], is.infinite)
    }
    
    date_df <- bind_cols(dates)
    
    #remove codes and clean up location names
    locations_df[] <- lapply(locations_df, gsub, pattern = ",", replacement = "")
    locations_df[] <- lapply(locations_df, gsub, pattern = "-", replacement = "")
    locations_df[] <- lapply(locations_df, gsub, pattern = "[0-9]", replacement = "")
    locations_df[] <- lapply(locations_df, gsub, pattern = "\\scard", replacement = "")
    locations_df[] <- lapply(locations_df, gsub, pattern = "Petr\\.\\)", replacement = "")
    locations_df[] <- lapply(locations_df, gsub, pattern = "Brunei Darussalam", replacement = "Brunei")
    locations_df[] <- lapply(locations_df, gsub, pattern = "Leporinum Australia", replacement = "Australia")
    locations_df[] <- lapply(locations_df, gsub, pattern = "Leporinum New Zealand", replacement = "New Zealand")
    locations_df[] <- lapply(locations_df, gsub, pattern = "Columbia", replacement = "Colombia")
    locations_df[] <- lapply(locations_df, gsub, pattern = "District of Colombia", replacement = "District of Columbia")
    locations_df[] <- lapply(locations_df, gsub, pattern = "Cote d''Ivoire", replacement = "Cote d'Ivoire")
    locations_df[] <- lapply(locations_df, gsub, pattern = "Faeroe", replacement = "Faroe")
    locations_df[] <- lapply(locations_df, gsub, pattern = "GuineaBissau", replacement = "Guinea")
    locations_df[] <- lapply(locations_df, gsub, pattern = "Himalaya", replacement = "Himalayas")
    locations_df[] <- lapply(locations_df, gsub, pattern = "Himalayass", replacement = "Himalayas")
    locations_df[] <- lapply(locations_df, gsub, pattern = "Italy Sicily", replacement = "Sicily")
    locations_df[] <- lapply(locations_df, gsub, pattern = "Malay Peninsula", replacement = "Malaysia")
    locations_df[] <- lapply(locations_df, gsub, pattern = "Russia Siberia", replacement = "Siberia")
    locations_df[] <- lapply(locations_df, function(x) str_trim(x, side = "both"))
    
    
    #combine location and codes into one dataframe and add host data
    colnames(locations_df) <- paste0("location", 1:ncol(locations_df))
    colnames(link_df) <- paste0("code", 1:ncol(locations_df))
    master_df <- cbind(locations_df, link_df, date_df)
    setDT(master_df)
    #master_df$host <- hosts
    master_df[, host := hosts]
    #master_df <- master_df[, c(ncol(master_df), 1:(ncol(master_df)-1))]
    master_df[]
    
    #melt locations/codes data
    locations_molten <- melt(master_df, id = "host")
    locations_molten2 <- locations_molten[grep("code", locations_molten$variable), ]
    locations_molten3 <- locations_molten[grep("date", locations_molten$variable), ]
    locations_molten <- locations_molten[grep("location", locations_molten$variable), ]
    #locations_molten$code <- locations_molten2$value
    #locations_molten$date <- locations_molten3$value
    locations_molten[, code := locations_molten2$value]
    locations_molten[, date := locations_molten3$value]
    locations_molten <- locations_molten[, -2]
    
    #combine lit codes into one column for each unique host/location pair
    locations_aggregated <- aggregate(data = locations_molten, code ~ host + value + date, paste, collapse = "###")
    
    #add numerical index for how many times each location appears
    setDT(locations_aggregated)
    locations_aggregated[, indx := 1:.N, by = value]
    
    #cast locations into wide format
    cast_locations <- data.table::dcast(locations_aggregated, value ~ indx, value.var = "host")
    cast_codes <- data.table::dcast(locations_aggregated, value ~ indx, value.var = "code")
    cast_dates <- data.table::dcast(locations_aggregated, value ~ indx, value.var = "date")
    cast_codes[] <- lapply(cast_codes, gsub, pattern = "###", replacement = ", ")
    
    cast_dates <- cast_dates %>%
      mutate(min=as.numeric(unlist(pmap(cast_dates, min, na.rm = T)))) %>%
      select(min) 
    
    locations_matrix <- as.matrix(cast_locations)
    codes_matrix <- as.matrix(cast_codes)
    
    locations_codes <- as.data.table(matrix(paste(locations_matrix, codes_matrix, sep=" - "), nrow=nrow(locations_matrix), dimnames=dimnames(locations_matrix)), stringsAsFactors = F)
    locations_codes[] <- lapply(locations_codes, gsub, pattern = " - NA", replacement="")
    
    cast_locations[ ,2:ncol(cast_locations)] <- locations_codes[ ,2:ncol(locations_codes)]
    
    mapping_df <- cast_locations
    colnames(mapping_df) <- c("location", paste("host", 1:(ncol(mapping_df)-1), sep = "_"))
    mapping_df <- merge(mapping_df, geocodes, by = "location")
    paste_args <- list("x" = mapping_df[,2:(ncol(mapping_df)-2)], "sep" = "; ", "na.rm" = T)
    mapping_df$hosts <- do.call(paste5, paste_args)
    mapping_df$hosts <- gsub("; NA", "", mapping_df$hosts) 
    mapping_df$label <- paste(sep = "<br/>", paste("Location:", mapping_df$location, sep = " "), 
                              paste("Hosts:", mapping_df$hosts, sep = " "))
    mapping_df <- mapping_df[, -(2:(ncol(mapping_df)-4))]
    #mapping_df$date <- cast_dates$min
    mapping_df[, date := cast_dates$min]
  
    
    
    
    
    
    
      
    
    ################################################################
    #combine location and codes into one dataframe and add host data
    colnames(locations_df) <- paste0("location", 1:ncol(locations_df))
    colnames(lit_codes_df) <- paste0("code", 1:ncol(locations_df))
    master_df <- cbind(locations_df, lit_codes_df)
    master_df$host <- hosts
    master_df <- master_df[, c(ncol(master_df), 1:(ncol(master_df)-1))]
    
    #melt locations/codes data
    locations_molten <- melt(master_df, id = "host")
    locations_molten2 <- locations_molten[grep("code", locations_molten$variable), ]
    locations_molten <- locations_molten[grep("location", locations_molten$variable), ]
    locations_molten$code <- locations_molten2$value
    locations_molten <- locations_molten[, c(1, 3, 4)]
    
    #combine lit codes into one column for each unique host/location pair
    locations_aggregated <- aggregate(data = locations_molten, code ~ host + value, paste, collapse = ",")
    
    #add numerical index for how many times each location appears
    setDT(locations_aggregated)
    locations_aggregated[, indx:=1:.N, by = value]
    setDF(locations_aggregated)
    
    #cast locations into wide format
    cast_locations <- dcast(locations_aggregated, value ~ indx, value.var = "host")
    cast_codes <- dcast(locations_aggregated, value ~ indx, value.var = "code") # ***THIS IS WHERE YOU STOPPED*****
    cast_codes[] <- lapply(cast_codes, gsub, pattern = ",", replacement = ", ")
    
    locations_matrix <- as.matrix(cast_locations)
    codes_matrix <- as.matrix(cast_codes)
    
    locations_codes <- as.data.frame(matrix(paste(locations_matrix, codes_matrix, sep=" - "), nrow=nrow(locations_matrix), dimnames=dimnames(locations_matrix)), stringsAsFactors = F)
    locations_codes[] <- lapply(locations_codes, gsub, pattern = " - NA", replacement="")
    
    cast_locations[ ,2:ncol(cast_locations)] <- locations_codes[ ,2:ncol(locations_codes)]
    
    mapping_df <- cast_locations
    colnames(mapping_df) <- c("location", paste("host", 1:(ncol(mapping_df)-1), sep = "_"))
    mapping_df <- merge(mapping_df, geocodes, by = "location")
    paste_args <- c(mapping_df[,2:(ncol(mapping_df)-4)], sep = "; ")
    mapping_df$hosts <- do.call(paste, paste_args)
    mapping_df$hosts <- gsub("; NA", "", mapping_df$hosts) 
    mapping_df$label <- paste(sep = "<br/>", paste("Location:", mapping_df$location, sep = " "), 
                            paste("Hosts:", mapping_df$hosts, sep = " "))
    mapping_df <- mapping_df[, -c(2:(ncol(mapping_df)-4))]
    
    
    ######THIS IS THE PART YOU WANT##########################################
    locations_list <- c(list(cast_locations), codes_list)
   
    first<-locations_list[[1]]
    second<-locations_list[[2]]
    third<-locations_list[[3]]
    
    first<-as.matrix(first)
    second<-as.matrix(second)
    third<-as.matrix(third)
    
    pasted<-as.data.frame(matrix(paste(second, third, sep=", "), nrow=nrow(second), dimnames=dimnames(second)))
    pasted[] <- lapply(pasted, gsub, pattern = ", NA", replacement="")
    
    pasted2<-as.data.frame(matrix(paste(first, second, sep=" - "), nrow=nrow(first), dimnames=dimnames(first)))
    #########################################################################

#name the list with fungi names
fungi_data <- pblapply(files, parse_fungi_html)
fungi_names <- sapply(sapply(fungi_data, "[[", 1), "[[", 1)
names(fungi_data) <- fungi_names

#make dataframe with unique locations for lookup
fungi_locations<-lapply(fungi_data, "[[", 4)
locations<-lapply(fungi_locations, '[', ,1,1)
locations<-unlist(locations, use.names = F)
locations<-unique(locations)
locations<-data.frame(location=locations, stringsAsFactors = F)
mapping_df$hosts<-do.call(paste5, df_args)

#dummy example
test<-fungi_data[[1]]
test_array<-test[[4]]

#to get geocodes, go to get_geocodes_fungi.R in dropbox, security concern on public github
geocodes <- read.csv("geocodes.csv", header = T, stringsAsFactors = F)
test_geocodes<-geocodes[which(test_array[,1,1] %in% geocodes$location),]
test_dims<-dim(test_array)
test_geocodes_list<-list(test_geocodes[,2:3])
for(i in 2:test_dims[3]){
  test_geocodes_list[[i]]<-data.frame("1"=rep(NA, test_dims[1]), "2"=rep(NA, test_dims[1]))
}
test_geocodes_array<-array(unlist(test_geocodes_list), dim=c(dim(test_geocodes_list[[1]]), length(test_geocodes_list)), dimnames = list(1:test_dims[1], c("lon", "lat"), 1:test_dims[3]))
test_bound_array<-abind(test_array, test_geocodes_array, along=2)

#modified paste function to suppress NAs in paste
paste5 <- function(..., sep = " ", collapse = NULL, na.rm = F) {
  if (na.rm == F)
    paste(..., sep = sep, collapse = collapse)
  else
    if (na.rm == T) {
      paste.na <- function(x, sep) {
        x <- gsub("^\\s+|\\s+$", "", x)
        ret <- paste(na.omit(x), collapse = sep)
        is.na(ret) <- ret == ""
        return(ret)
      }
      df <- data.frame(..., stringsAsFactors = F)
      ret <- apply(df, 1, FUN = function(x) paste.na(x, sep))
      
      if (is.null(collapse))
        ret
      else {
        paste.na(ret, sep = collapse)
      }
    }
}

mapping_df<-data.frame(test_bound_array[,,1], stringsAsFactors = F)
mapping_df$lon<-as.numeric(mapping_df$lon)
mapping_df$lat<-as.numeric(mapping_df$lat)
df_args<-c(mapping_df[,2:(ncol(mapping_df)-2)], sep="; ", na.rm=T)
mapping_df$hosts<-do.call(paste5, df_args)

mapping_df$label<-paste(sep="<br/>", paste("Location:", mapping_df$V1, sep=" "), 
                        paste("Hosts:", mapping_df$hosts, sep=" "))


paste(sep=", ", mapping_df[2:ncol(mapping_df)-2])

map <- leaflet(data = mapping_df) %>%
  addTiles() %>%
  addMarkers(~lon, ~lat, popup=mapping_df$label)


mapping_df$label<-paste(sep="<br/>", paste("Location:", mapping_df$V1, sep=" "), 
                        paste("Hosts:", mapping_df$hosts, sep=" "))


##random stuff
fungi_locations[which(grepl(fungi_locations, "Rica"))]

fungi_nomenclature<-lapply(fungi_data, "[[", 1)
fungi_nomenclature<-unlist(fungi_nomenclature)
fungi_nomenclature<-unique(fungi_nomenclature)
fungi_nomenclature<-data.frame(name=fungi_nomenclature)

fungi_data$`Alternaria carotae`$geocodes<-data.frame(locations=fungi_data$`Alternaria carotae`$locations_hosts[,1,1], stringsAsFactors = F)
geocodes<-fungi_data$`Alternaria carotae`$geocodes
geocodes[]<-lapply(geocodes, gsub, pattern="USSR", replacement="Sovient Union")

geocode_sf <- st_as_sf(geocodes, coords = c("lon", "lat"), crs = 4326)
mapview(geocode_sf)

map <- leaflet(data = geocodes) %>%
  addTiles() %>%
  addLabelOnlyMarkers(~lon, ~lat, label = ~as.character(location), labelOptions = labelOptions(noHide = T, direction = 'top'))


#split multiple lit codes into separate columns
max_code <- strsplit(locations_aggregated$code, ",")
max_code_length <- max(lengths(max_code))
locations_aggregated <- separate(locations_aggregated, code, into = paste("code", 1:max_code_length, sep = "_"), sep = ",", convert = T)

#cast codes into wide format, separate dataframe for each "level" of code
codes_list <- list()
for(i in 1:max_code_length){
  codes_list[[i]] <- dcast(locations_aggregated, value ~ indx, value.var = paste("code", i, sep = "_"))
}

leaflet(data = mapping_df) %>%
  addTiles() %>%
  addMarkers(~lon, ~lat, popup=mapping_df$label)


##trying to compress gsubs--didn't work
patterns <- c("\\(([^\\)]+)\\)", "\\*", ";\\s", "ontario", "Abyssinics", "Andreana", "Arborescens", "Aristata",
              "Basilaris", "Baumannii", "Berberis Ilicifolia", "Briotii", "Canaertii", "Chia", "Cicadellidae", 
              "Condensata", "Conspicuus", "Cordyluridae:", "Densa", "Diptera", "Dregeanus", "Elegantissima", 
              "Glabrata", "Glauca", "Globosa", "Grandiflora", "Homoptera", "Hymenoptera", "Islands", "Japonicus:",
              "Japonicus", "Lalandei", "Leporinum", "Longipinnatus", "Mantica", "Pteridophyta", "Pubens", "Pyramidalis", 
              "Recurvifolia", "Rotundifolia", "Rough", "Spp", "Squarrosa :", "Suffruticosa", "Thunbergii", "Tripartita", 
              "Vittatum", "Perennis", "Rica", "USSR", "South Africa Unknown", "Czechoslovakia", "Dakota", 
              "Pacific islands", "Northwestern States", "Southwestern States", "Tropical America", "Jersey", 
              "Zambia zim", "Gulf states", "Java", "Congo\\, Democratic Republic of the", "Georgia\\, Republic of", 
              "Christmas Island\\, Territory of", "Congo\\, Republic of the")
replacements <- c("", "", ",", "Ontario", "abyssinics", "andreana", "arborescens", "aristata", "basilaris", 
                  "baumannii", "berberis ilicifolia", "briotii", "canaertii", "chia", "cicadellidae", "condensata", 
                  "conspicuus", "cordyluridae", "densa", "diptera", "dregeanus", "elegantissima", "glabrata", 
                  "glauca", "globosa", "grandiflora", "homoptera", "hymenoptera", "islands", "japonicus", 
                  "japonicus", "lalandei", "Leporinum", "longipinnatus", "mantica", "pteridophyta", "pubens",
                  "pyramidalis", "recurvifolia", "rotundifolia", "rough", "spp", "squarrosa", "suffruticosa", 
                  "thunbergii", "tripartita", "vittatum", "perennis", "Costa Rica", "Poland", "South Africa", 
                  "Czech Republic", "North Dakota", "Polynesia", "Pacific Northwest States", "Southwest United States", 
                  "Central America", "New Jersey", "Zambia", "United States Gulf Coast", "Indonesia Java", 
                  "Congo", "Republic of Georgia", "Christmas Island", "Congo")

locations <- str_replace_all(locations, patterns, replacements)

locations <- gsub(locations, pattern = "Costa Costa Rica", replacement = "Costa Rica")
locations <- gsub(locations, pattern = "New New Jersey", replacement = "New Jersey")
locations <- gsub(locations, pattern = "Indonesia Indonesia Java", replacement = "Indonesia Java")
locations <- gsub(locations, pattern = "North North Dakota", replacement = "North Dakota")