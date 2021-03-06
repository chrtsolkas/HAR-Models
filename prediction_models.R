invisible(source("import_data.R"))
library(dplyr)

# How many users
unique(train_set$user_name)
table(train_set$user_name)

# how many classes and their distribution
unique(train_set$classe)
table(train_set$classe)

## Clean the data set
NApercentage <- .05 # Allow 5% NAs in data columns
lowNAcolumns <- names(train_set)[colMeans(is.na(train_set)) < NApercentage]

# Drop columns that are filled with NAs
train_set <- train_set[, lowNAcolumns]
test_set <- test_set[, lowNAcolumns[-length(lowNAcolumns)]]

# Drop record count column (V1), the user name and the timing columns 
train_set <- train_set %>%
  select(-c("V1",
            "user_name",
            "raw_timestamp_part_1", 
            "raw_timestamp_part_2", 
            "cvtd_timestamp", 
            "new_window", 
            "num_window")
         )

test_set <- test_set %>%
  select(-c("V1", 
            "user_name",
            "raw_timestamp_part_1", 
            "raw_timestamp_part_2", 
            "cvtd_timestamp", 
            "new_window", 
            "num_window")
  )

sum(colSums(is.na(train_set))) # Now there are no NAs

# 
# train_set$cvtd_timestamp <- strptime(train_set$cvtd_timestamp, "%d/%m/%Y %H:%M")
# 
# sapply(train_set, class)
# sapply(test_set, class)

library(randomForest)
library(caret)

#Use repeated cross validation: use 10 folds and repeat 3 times
# It takes around 30 minutes to run
control <- trainControl(method='repeatedcv', 
                        number=10, 
                        repeats=3)

# Set the seed for reproducibility
set.seed(123)

#Set mtry to the square root of the number of features used in the model
mtry <- round(sqrt(ncol(train_set)))

# tunegrid contains only the hyperparameter mtry
tunegrid <- expand.grid(.mtry=mtry)

# Train the model and time the process (it takes around 30 minutes with an i5 processor)
system.time({
  rf_model <- train(classe ~ ., 
                      data=train_set, 
                      method='rf', 
                      metric='Accuracy', 
                      tuneGrid=tunegrid, 
                      trControl=control)
})

# Print the model
print(rf_model)

# Plot the variable importance for the final model choosen
varImpPlot(rf_model$finalModel)

# make dataframe from importance() output
feat_imp_df <- importance(rf_model$finalModel) %>% 
  data.frame() %>% 
  mutate(feature = row.names(.)) %>%
  slice_max(n = 20)

# plot dataframe
ggplot(feat_imp_df, aes(x = reorder(feature, MeanDecreaseGini), 
                        y = MeanDecreaseGini)) +
  geom_bar(stat='identity') +
  labs(
    x     = "Feature",
    y     = "Importance (Mean Decrease of Gini)",
    title = "Feature Importance: classe ~ ."
  ) +
  coord_flip() +
  theme_classic()
   
# Plot the final model
plot(rf_model$finalModel)

# Predict the classes for the test set
rfModel_predict <- predict(rf_model, newdata = test_set, type = "raw")

# Print the predictions
print(rfModel_predict)
# B A B A A E D B A A B C B A E E A B B B


trellis.par.set(caretTheme())
plot(rf_model$finalModel)  
