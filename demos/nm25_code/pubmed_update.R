# Load necessary libraries
library(jsonlite)
library(xml2)
library(readr)
library(readxl)
library(dplyr)
library(stringr)
library(tidyr)
library(janitor)
library(httr)
library(writexl)

# Search settings
start_date <- "2025/08/01"
end_date <- format(Sys.Date(), "%Y/%m/%d")

search_query <- paste0(
    '((refugee[Title/Abstract] OR displaced[Title/Abstract] OR idp[Title/Abstract] OR "asylum seeker"[Title/Abstract] OR migrant[Title/Abstract] OR stateless[Title/Abstract] OR returnee[Title/Abstract])',
    ' AND ',
    '(emergency[Title/Abstract] OR border[Title/Abstract] OR "host community"[Title/Abstract] OR centre[Title/Abstract] OR center[Title/Abstract] OR camp[Title/Abstract] OR displacement[Title/Abstract] OR conflict[Title/Abstract] OR humanitarian[Title/Abstract] OR migration[Title/Abstract])',
    ' AND ',
    'health[Title/Abstract]',
    ' AND ',
    '(implementation[Title/Abstract] OR evaluation[Title/Abstract] OR intervention[Title/Abstract] OR service[Title/Abstract] OR program[Title/Abstract] OR programme[Title/Abstract] OR assessment[Title/Abstract] OR delivery[Title/Abstract] OR system[Title/Abstract] OR access[Title/Abstract]))',
    ' AND ',
    '("', start_date, '"[Date - Publication] : "', end_date, '"[Date - Publication])'
)

# Load the previous data
previous <- readxl::read_xlsx("demos/nm25_code/all_assigned_papers.xlsx")
previous <- janitor::clean_names(previous)

# Define health domain keywords
domain_keywords <- list(
    "Infectious disease" = c("infectious", "infection", "virus", "viral", "bacteria", "malaria", "HIV", "tuberculosis", "COVID", "dengue", "cholera", "outbreak", "immunization","vaccination", "hiv", "vaccine campaign", "immunisation", "diarrheal disease"),
    "Malnutrition (and associated morbidities)" = c("malnutrition", "nutrition", "stunting", "wasting", "undernutrition", "anemia", "deficiency", "anaemia", "iron", "cooking pots"),
    "Mental and psychosocial health" = c("mental health", "psychosocial", "depression", "anxiety", "PTSD", "trauma", "psychological", "mental disorder", "psychometric", "special needs", "mindfulness", "wellbeing", "coping skills", "SenseMaker", "suicide prevention", "stigma reduction", "substance use services", "suicide"),
    "Reproductive, maternal and child health" = c("maternal", "child health", "reproductive", "pregnancy", "neonatal", "infant", "antenatal", "postnatal", "birth", "child protection", "menstrual", "menstruation", "menstruator", "early child", "children's surgical care", "family planning among married women"),
    "Sexual and gender-based violence" = c("sexual violence", "gender-based violence", "GBV", "rape", "sexual assault", "domestic violence", "intimate partner violence", "early marriage", "child marriage", "sexuality", "adolescent girls"),
    "Non-communicable diseases" = c("non-communicable", "chronic disease", "NCD", "diabetes", "hypertension", "cancer", "cardiovascular", "stroke", "oral health", "dental care", "rehabilitation", "palliative care", "lung function", "rheumatic heart disease", "postprandial blood glucose"),
    "WASH" = c("WASH", "hygiene", "sanitation", "handwashing", "chlorinator", "dry toilets", "sanitation uptake", "noncommunicable diseases", "diarrheal disease", "Drinking water system treatment"),
    "Other (Health Systems, School Violence, Research Methods)" = c("teacher violence", "mHealth", "health data management", "electronic health record system", "health services", "community project", "EmpaTeach", "healthcare services", "focus groups", "collaborative blended learning", "hesper web", "response training", "problem management plus", "telemedicine", "short-term medical mission", "access to urban migrant healthcare", "clean mind-dirty hands", "community-based mortality surveillance", "Evaluation of a surgical service", "One health education")
)

# Function to scan all domains and return TRUE/FALSE for each domain
scan_domains <- function(text, keywords_list) {
    text <- tolower(text)
    sapply(keywords_list, function(keywords) {
        pattern <- paste(tolower(keywords), collapse = "|")
        str_detect(text, pattern)
    })
}

# Search PubMed
base_url <- "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
search_text <- httr::GET(
    base_url,
    query = list(
        db = "pubmed",
        retmode = "json",
        retmax = 10000,
        term = search_query
    )
) |>
    httr::content(as = "text", encoding = "UTF-8")

search_res <- jsonlite::fromJSON(search_text)
pmids <- search_res$esearchresult$idlist
message("PubMed count: ", search_res$esearchresult$count)

# Fetch PubMed records
fetch_chunk <- function(ids) {
    fetch_res <- read_xml(
        httr::GET(
            "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi",
            query = list(db = "pubmed", retmode = "xml", id = paste(ids, collapse = ","))
        )
    )

    articles <- xml_find_all(fetch_res, ".//PubmedArticle")

    bind_rows(lapply(articles, function(article) {
        title <- article |>
            xml_find_first(".//ArticleTitle") |>
            xml_text()

        abstract <- article |>
            xml_find_all(".//Abstract/AbstractText") |>
            xml_text() |>
            paste(collapse = " ")

        tibble(
            pmid = article |> xml_find_first(".//PMID") |> xml_text(),
            title = title,
            abstract = abstract
        )
    }))
}

chunks <- split(pmids, ceiling(seq_along(pmids) / 200))
papers <- bind_rows(lapply(chunks, fetch_chunk))

papers$title <- gsub("\005", "", papers$title, fixed = TRUE)
papers$title <- gsub("\006", "", papers$title, fixed = TRUE)
previous$title <- gsub("\005", "", previous$title, fixed = TRUE)
previous$title <- gsub("\006", "", previous$title, fixed = TRUE)

# Apply classification to each paper (combine title and abstract)
domain_matches <- papers %>%
    mutate(combined_text = paste(title, abstract, sep = " ")) %>%
    rowwise() %>%
    mutate(matches = list(scan_domains(combined_text, domain_keywords))) %>%
    unnest_wider(matches)

# Combine domain matches back to papers dataframe
papers <- bind_cols(papers, domain_matches %>% select(names(domain_keywords)))

# add unassigned
papers <- papers %>%
    mutate(Unassigned = if_else(rowSums(across(names(domain_keywords))) == 0, TRUE, FALSE))

# Check results
domcols <- c(names(domain_keywords), "Unassigned")
summary(papers %>% select(all_of(domcols)))

# Summarise the total number of papers per domain
domain_summary <- papers %>%
    summarise(across(all_of(domcols), sum)) %>%
    pivot_longer(everything(), names_to = "Health_Domain", values_to = "Paper_Count")

print(domain_summary)

# identify those extra from the original sent
new <- papers[which(is.na(match(tolower(trimws(papers$title)), tolower(trimws(previous$title))))),]

# write to file
writexl::write_xlsx(papers %>% mutate(across(all_of(domcols), as.integer)), "demos/nm25_code/pubmed_update_all_assigned_papers.xlsx")
writexl::write_xlsx(new %>% mutate(across(all_of(domcols), as.integer)), "demos/nm25_code/pubmed_update_extra_assigned_papers.xlsx")
write_csv(domain_summary, "demos/nm25_code/pubmed_update_domain_summary.csv")
