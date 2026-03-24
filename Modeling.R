library(e1071)
library(caret)
library(ROCR)

#Read from csv generated from Python script or otherwise

marchmad = read.csv("~/March Madness Data.csv",header = T)

#Sample training testing split

index = sample(seq(1:189),size = 126,replace = FALSE)
marchmad_train = marchmad[index,]
marchmad_test = marchmad[-index,]

#Predict point differentials, using various linear models and a Support Vector Machine, testing with MSE

marchmad.regress = lm(PointDiff~DORtg + DDRtg,data = marchmad_train)
marchmad.regress1 = lm(PointDiff~DORtg + DDRtg + DadjT + DnetRtg + DadjT*DnetRtg,data = marchmad_train)
marchmad.svm = svm(PointDiff~DORtg + DDRtg,data = marchmad_train,kernel='linear')
regress_predict = predict(marchmad.regress,newdata = marchmad_test)
svm_predict = predict(marchmad.svm,newdata = marchmad_test)
PointDiff_test = marchmad_test[,8]
sum((regress_predict-PointDiff_test)^2)
sum((svm_predict-PointDiff_test)^2)

#Predict win probability, using various logistic models and a Support Vector Machine, testing with confusion matrix

marchmad.logit = glm(Win~DORtg + DDRtg,family = 'binomial',data = marchmad_train)
marchmad.logit1 = glm(Win~DORtg + DDRtg + DadjT + DnetRtg + DadjT*DnetRtg,family = 'binomial',data = marchmad_train)
marchmadprob.svm = svm(Win~DORtg + DDRtg,data = marchmad_train,kernel='radial',type = 'C-classification',
                       probability = TRUE)
logit_predict = predict(marchmad.logit,newdata = marchmad_test,type = 'response')
logit_predictions = ifelse(logit_predict > 0.5,1,0)
svmprob_predict = predict(marchmadprob.svm,newdata = marchmad_test,probability = TRUE)
svmprob_predictions = as.numeric(as.vector(svmprob_predict))
svmprob_probabilities = attr(svmprob_predict, "probabilities")[,2]
Win_test = as.numeric(marchmad_test[,7])
confusionMatrix(data = as.factor(logit_predictions),reference = as.factor(Win_test))
confusionMatrix(data = as.factor(svmprob_predictions),reference = as.factor(Win_test))

#Checking residual plots and Normality assumptions

marchmad.regress = lm(PointDiff~DORtg + DDRtg,data = marchmad)
plot(marchmad.regress$fitted.values,marchmad.regress$residuals)
shapiro.test(marchmad.regress$residuals)

#Checking ROC curve

marchmad.logit = glm(Win~DORtg + DDRtg,family = 'binomial',data = marchmad)
pred = prediction(marchmad.logit$fitted.values,marchmad$Win)
perf = performance(pred,measure = 'tpr',x.measure = 'fpr')
plot(perf,colorize = T)
performance(pred,"auc")@y.values

#Load in new data

marchmadnew = read.csv("~/newpredict.csv",header = T)

#Use predictions on models chosen from previously

predict(marchmad.regress,newdata = marchmadnew)
predict.glm(marchmad.logit,type = "response",newdata = marchmadnew)

#Kelly criterion for bet sizing as fun bonus

kelly_criterion = function(mult,prob,amodds){
  b = 0
  if(amodds < 0){
    b = 100/abs(amodds)
  }
  if(amodds > 0){
    b = abs(amodds)/100
  }
  return(mult*(prob - ((1-prob)/b)))
}
kelly_criterion(.5,.925,-1200)
