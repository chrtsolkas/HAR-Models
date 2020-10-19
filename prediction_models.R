invisible(source("import_data.R"))
library(dplyr)

unique(train_set$user_name)
table(train_set$user_name)

unique(train_set$classe)
table(train_set$classe)

# train_set <- train_set %>%
#   mutate(classe = factor(classe),
#          user_name = factor(user_name),
#          cvtd_timestamp = as.POSIXlt(cvtd_timestamp, "%d/%m/%Y %H:%M"),
#          new_window = factor(new))


library(randomForest)
library(caret)



########################

nonNAcolumns <- names(train_set)[colSums(is.na(train_set)) == 0]

nonNA_train_set <- train_set[, nonNAcolumns]
nonNA_train_set <- nonNA_train_set %>%
  select(-c("V1", "raw_timestamp_part_1", "raw_timestamp_part_2", 
            "cvtd_timestamp", "new_window", "num_window"))

set.seed(3456)
trainIndex <- createDataPartition(nonNA_train_set$classe, p = .8, 
                                  list = FALSE, 
                                  times = 1)
rfTrain <- nonNA_train_set[ trainIndex,]
rfTest  <- nonNA_train_set[-trainIndex,]

sapply(rfTrain, class)

set.seed(123)
rf <-randomForest(classe~.,
                  data = rfTrain, 
                  ntree = 100, 
                  mtry = sqrt(ncol(rfTrain)),
                  importance = TRUE, 
                  na.action = na.omit
) 
print(rf)
plot(rf)
#Evaluate variable importance
# importance(rf)
# importance(rf)[order(importance(rf)[,"MeanDecreaseGini"], decreasing = TRUE),]
varImpPlot(rf)

# names(test_set[, nonNAcolumns[-length(nonNAcolumns)]])
# names(nonNA_train_set)
# names(test_set[, nonNAcolumns[-length(nonNAcolumns)]])
# nonNAcolumns

frc_rf <- predict(rf, rfTest)

trellis.par.set(caretTheme())
plot(rf)  

#10 folds repeat 3 times
control <- trainControl(method='repeatedcv', 
                        number=10, 
                        repeats=3)

set.seed(123)

#Number randomly variable selected is mtry
mtry <- sqrt(ncol(nonNA_train_set))

tunegrid <- expand.grid(.mtry=mtry)

system.time({
  rf_default <- train(classe ~ ., 
                      data=nonNA_train_set, 
                      method='rf', 
                      metric='Accuracy', 
                      tuneGrid=tunegrid, 
                      trControl=control)
})


print(rf_default)
varImpPlot(rf_default$finalModel)
plot(rf_default$finalModel)

control <- trainControl(method='repeatedcv', 
                        number=10, 
                        repeats=3, 
                        search='grid')
tunegrid <- expand.grid(.mtry=(1:15))
set.seed(123)
system.time({
  rf_grid <- train(classe ~ ., 
                      data=nonNA_train_set, 
                      method='rf', 
                      metric='Accuracy', 
                      tuneGrid=tunegrid, 
                      trControl=control)
})

print(rf_grid)
varImpPlot(rf_grid$finalModel)
plot(rf_grid$finalModel)
##################################################################
# XGBOOST - eXtreme Gradient Boosting for regression
##################################################################
library(xgboost)
library(caret)
library(dplyr)

#set.seed(123)
# Create index for testing and training data
#inTrain <- createDataPartition(y = Data_ml[,-1]$Prices.BE, p = 0.8, list = FALSE)
# subset power_plant data to training
#training <- Data_ml[inTrain,-1]
# subset the rest to test
#testing <- Data_ml[-inTrain,-1]

# Training set
training <- insample_ml[,-1]
training$Date <- NULL

# For final validation
X_outsample <- outsample_ml[,-1]
X_outsample$Date <- NULL

#testing$Date <- NULL
#sapply(training, class)
X_train = xgb.DMatrix(as.matrix(training %>% select(-Prices.BE)))
#X_train = xgb.DMatrix(as.matrix(insample_tr_data %>% select(-Prices.BE)))
y_train = training$Prices.BE
#y_train = insample_tr_data$Prices.BE
X_outsample = xgb.DMatrix(as.matrix(X_outsample %>% select(-Prices.BE)))
#X_outsample = xgb.DMatrix(as.matrix(outsample_tr_data %>% select(-Prices.BE)))
#X_test = xgb.DMatrix(as.matrix(testing %>% select(-Prices.BE)))
#y_test = testing$Prices.BE

# 5-fold cross validation with 3 repeats and parallel processing
xgb_trcontrol = trainControl(
  method = "repeatedcv",
  #method = "cv",
  number = 10,
  repeats = 10,
  allowParallel = TRUE,
  verboseIter = FALSE,
  returnData = FALSE
)

# best parameters for gblTree
#xgbGrid <- expand.grid(nrounds = 150,  
#                       max_depth = 3,
#                       colsample_bytree = 0.8,
#                       eta = 0.4,
#                       gamma=0,
#                       min_child_weight = 1,
#                       subsample = 1
#)

# best parameters for gblLinear
xgbGrid <- expand.grid(nrounds = 150,  
                       eta = 0.3,
                       alpha = 0,
                       lambda = 0
)

set.seed(50)
xgb_model <- caret::train(
  X_train, y_train,  
  trControl = xgb_trcontrol,
  #tuneGrid = xgbGrid,
  #method = "xgbTree"
  method="xgbLinear"
)

xgb_model$bestTune

varImp(xgb_model)

frc_xgb <- predict(xgb_model, X_outsample) 
Evaluation$sMAPE[7] <- sMAPE(outsample, frc_xgb) 

#trellis.par.set(caretTheme())
#plot(xgb_model)
