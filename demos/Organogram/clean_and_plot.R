df <- data.frame(readxl::read_excel("C:/Users/Oliver/Desktop/malariagroup.xlsx",sheet=3)[,1:12])
str(df)
df$Research <- apply(df[,7:12],MARGIN = 1,function(x) paste(na.omit(x),collapse=","))
df$label = df$Name
names(df)[c(1,4)] <- c("id","Second.Supervisor")

from <- to <- lones <- level <- c()

for(i in 1:dim(df)[1]){

    if(!is.na(df$Supervisor[i])){
    from <- c(from,df$id[match(df$Supervisor[i],df$Name)])
    to <- c(to,df$id[i])
    } else {
        if(df$Name[i]!="Neil"){
        lones <- c(lones,df$id[i])
        }
    }
    if(!is.na(df$Second.Supervisor[i])){
        to <- c(to,df$id[i])
        from <- c(from,df$id[match(df$Second.Supervisor[i],df$Name)])
    }
    if(!is.na(df$Unofficial.3rd.Supervisor[i])){
        to <- c(to,df$id[i])
        from <- c(from,df$id[match(df$Unofficial.3rd.Supervisor[i],df$Name)])
    }

    if(is.na(df$Supervisor[i])){
        level <- c(level,0)
    } else if(df$Supervisor[i]=="Neil" && is.na(df$Second.Supervisor[i])){
        level <- c(level,1)
    } else if (!is.na(df$Supervisor[i]) && is.na(df$Second.Supervisor[i])){
        level <- c(level,2)
    } else if (!is.na(df$Supervisor[i]) && !is.na(df$Second.Supervisor[i]) && is.na(df$Unofficial.3rd.Supervisor[i])){
        level <- c(level,2)
    } else {
        level <- c(level,3)
    }

}

temp <- df[, TRUE, drop = FALSE]
temp <- vapply(names(df),
               function(e) paste(e, temp[, e], sep = ": "),
               character(nrow(nodes)))
df$title <- paste("<p>",
                  apply(temp, 1, paste0, collapse = "<br>"), "</p>")

df$level <- level
df$label2 <- df$label
df$label <- as.character(sapply(df$label2,function(x){paste0(paste(rep("    ",8),collapse=""),x)}))
df$color = sample(colors(),size = 14)[as.numeric(factor(df$Position))]
contacts <- data.frame("from"=from,"to"=to)
save(df,contacts,file = paste0(getwd(),"network.RData"))
graph <-  visNetwork::visNetwork(df,contacts,directed=TRUE,width = "2000px",height="800px") %>%
    visNetwork::visHierarchicalLayout(levelSeparation = 1200,nodeSpacing = 20,direction = "LR",blockShifting = T) %>%
    visNetwork::visEdges(arrows = "to") %>%
    visNetwork::visNodes(font = list("size"=48,"vadjust"=-72,"align"="center"),
                         size = 20) %>%
    visNetwork::visOptions(selectedBy = list(variable = "Research", multiple = T)) %>%
    visNetwork::visLegend(ncol = 1,stepY = 40)

visSave(graph,paste0(getwd(),"organogram.html"))
