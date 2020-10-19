# Download the training file only if this was not already done
if(!file.exists("pml-training.csv")) {
  download.file("https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv", destfile = "pml-training.csv")
}

if(!file.exists("pml-testing.csv")) {
  download.file("https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv", destfile = "pml-testing.csv")
}

library(data.table)

# Read the two data files if this was not already done
if (!("train_set" %in% ls())) {
  train_set <- fread("pml-training.csv", data.table = FALSE)
  
}

if (!("test_set" %in% ls())) {
  test_set <- fread("pml-testing.csv", data.table = FALSE)
  
}

# summary(train_set)
# str(train_set)
# 
# colSums(is.na(train_set))  # There are no NAs in data

# summary(test_set)
# str(test_set)
# 
# colSums(is.na(test_set))  # There are no NAs in data
