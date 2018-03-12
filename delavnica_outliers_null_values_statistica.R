¸### http://www.math.csi.cuny.edu/Statistics/R/simpleR/printable/simpleR.pdf
### http://www.r-tutor.com/elementary-statistics/probability-distributions/binomial-distribution
### https://cran.r-project.org/doc/contrib/Seefeld_StatsRBio.pdf


# probability examples


####################################
######    outliers
###################################

# Inject outliers into dats
cars1 <- cars[1:30, ]  # original data
cars_outliers <- data.frame(speed=c(19,19,20,20,20), dist=c(190, 186, 210, 220, 218))  # introduce outliers.
cars2 <- rbind(cars1, cars_outliers) 



# Plot of data with outliers.
par(mfrow=c(1, 2))
plot(cars2$speed, cars2$dist, xlim=c(0, 28), ylim=c(0, 230), main="With Outliers", xlab="speed", ylab="dist", pch="*", col="red", cex=2)
abline(lm(dist ~ speed, data=cars2), col="blue", lwd=3, lty=2)


# Plot of original data without outliers. Note the change in slope (angle) of best fit line.
plot(cars1$speed, cars1$dist, xlim=c(0, 28), ylim=c(0, 230), main="Outliers removed \n A much better fit!", xlab="speed", ylab="dist", pch="*", col="red", cex=2)
abline(lm(dist ~ speed, data=cars1), col="blue", lwd=3, lty=2)

par(mfrow=c(1, 1))
## detecting outliers

# Univariate approach
url <- "http://rstatistics.net/wp-content/uploads/2015/09/ozone.csv"  
# alternate source:  https://raw.githubusercontent.com/selva86/datasets/master/ozone.csv
inputData <- read.csv(url)  # import data
inputData <- read.csv("C:\\DataTK\\ozone.csv")

outlier_values <- boxplot.stats(inputData$pressure_height)$out  # outlier values.
boxplot(inputData$pressure_height, main="Pressure Height", boxwex=0.1)
mtext(paste("Outliers: ", paste(outlier_values, collapse=", ")), cex=0.6)

ozone <- inputData

## Bivariate approach
# For categorical variable
boxplot(ozone_reading ~ Month, data=ozone, main="Ozone reading across months")  # clear pattern is noticeable.
boxplot(ozone_reading ~ Day_of_week, data=ozone, main="Ozone reading for days of week")  # this may not be significant, as day of week variable is a subset of the month var.


# For continuous variable (convert to categorical if needed.)
boxplot(ozone_reading ~ pressure_height, data=ozone, main="Boxplot for Pressure height (continuos var) vs Ozone")
boxplot(ozone_reading ~ cut(pressure_height, pretty(inputData$pressure_height)), data=ozone, main="Boxplot for Pressure height (categorial) vs Ozone", cex.axis=0.5)


#Multivariate approach
#coocks distance

mod <- lm(ozone_reading ~ ., data=ozone)
cooksd <- cooks.distance(mod)

plot(cooksd, pch="*", cex=2, main="Influential Obs by Cooks distance")  # plot cook's distance
abline(h = 4*mean(cooksd, na.rm=T), col="red")  # add cutoff line
text(x=1:length(cooksd)+1, y=cooksd, labels=ifelse(cooksd>4*mean(cooksd, na.rm=T),names(cooksd),""), col="red")  # add labels



influential <- as.numeric(names(cooksd)[(cooksd > 4*mean(cooksd, na.rm=T))])  # influential row numbers
head(ozone[influential, ])  # influential observations.

#outliers test
car::outlierTest(mod)


#outliers package
install.packages("outliers")
library(outliers)


set.seed(1234)
y=rnorm(10)hhb
outlier(y)
outlier(y, opposite=TRUE)

set.seed(12)
x <- rnorm(10)
x
scores(x)
scores(x, type="chisq")
scores(x, type="t")
scores(x, type="z")


### URL: http://r-statistics.co/Missing-Value-Treatment-With-R.html#3.%20Imputation%20with%20mean%20/%20median%20/%20mode

# treating outliers
 # 0) Capping
x <- ozone$pressure_height
qnt <- quantile(x, probs=c(.25, .75), na.rm = T)
caps <- quantile(x, probs=c(.05, .95), na.rm = T)
H <- 1.5 * IQR(x, na.rm = T)
x[x < (qnt[1] - H)] <- caps[1]
x[x > (qnt[2] + H)] <- caps[2]


 # 1) imputation
library(Hmisc)
impute(BostonHousing$ptratio, mean)  # replace with mean
impute(BostonHousing$ptratio, median)  # median
impute(BostonHousing$ptratio, 20)  # replace specific number
# or if you want to impute manually
BostonHousing$ptratio[is.na(BostonHousing$ptratio)] <- mean(BostonHousing$ptratio, na.rm = T)  # not run

library(DMwR)
actuals <- original$ptratio[is.na(BostonHousing$ptratio)]
predicteds <- rep(mean(BostonHousing$ptratio, na.rm=T), length(actuals))
regr.eval(actuals, predicteds)
#>        mae        mse       rmse       mape 
#> 1.62324034 4.19306071 2.04769644 0.09545664


# 2) kNN imputation
library(DMwR)
knnOutput <- knnImputation(BostonHousing[, !names(BostonHousing) %in% "medv"])  # perform knn imputation.
anyNA(knnOutput)
#> FALSE

actuals <- original$ptratio[is.na(BostonHousing$ptratio)]
predicteds <- knnOutput[is.na(BostonHousing$ptratio), "ptratio"]
regr.eval(actuals, predicteds)
#>        mae        mse       rmse       mape 
#> 1.00188715 1.97910183 1.40680554 0.05859526 

# 3) Multivariate imputation by chained equations

library(mice)
miceMod <- mice(BostonHousing[, !names(BostonHousing) %in% "medv"], method="rf")  # perform mice imputation, based on random forests.
miceOutput <- complete(miceMod)  # generate the completed data.
anyNA(miceOutput)
#> FALSE

actuals <- original$ptratio[is.na(BostonHousing$ptratio)]
predicteds <- miceOutput[is.na(BostonHousing$ptratio), "ptratio"]
regr.eval(actuals, predicteds)
#>        mae        mse       rmse       mape 
#> 0.36500000 0.78100000 0.88374204 0.02121326

actuals <- original$rad[is.na(BostonHousing$rad)]
predicteds <- miceOutput[is.na(BostonHousing$rad), "rad"]
mean(actuals != predicteds)  # compute misclass error.
#> 0.15






#### distributions




##############################

#### Feature selection

#############################

# with random rofest method
#####################
inputData <- read.csv("http://rstatistics.net/wp-content/uploads/2015/09/ozone1.csv", stringsAsFactors=F)
library(party)
cf1 <- cforest(ozone_reading ~ . , data= inputData, control=cforest_unbiased(mtry=2,ntree=50)) # fit the random forest

varimp(cf1) # get variable importance, based on mean decrease in accuracy
#to plot
#importance(cf1)
#plot(varimp(cf1))

varimp(cf1, conditional=TRUE)  # conditional=True, adjusts for correlations between predictors
varimpAUC(cf1)  # more robust towards class imbalance.


#with relative importance method
#####################
install.packages("relaimpo")
library(relaimpo)

lmMod <- lm(ozone_reading ~ . , data = inputData)  # fit lm() model
relImportance <- calc.relimp(lmMod, type = "lmg", rela = TRUE)  # calculate relative importance scaled to 100
sort(relImportance$lmg, decreasing=TRUE)


#with MARS
#####################
#The earth package implements variable importance based on 
#Generalized cross validation (GCV), number of subset models the 
#variable occurs (nsubsets) and residual sum of squares (RSS).

library(earth)
marsModel <- earth(ozone_reading ~ ., data=inputData) # build model
ev <- evimp (marsModel) # estimate variable importance
ev

plot(ev)

#with Regresssion
#####################


base.mod <- lm(ozone_reading ~ 1 , data= inputData)  # base intercept only model
all.mod <- lm(ozone_reading ~ . , data= inputData) # full model with all predictors
stepMod <- step(base.mod, scope = list(lower = base.mod, upper = all.mod), direction = "both", trace = 0, steps = 1000)  # perform step-wise algorithm
shortlistedVars <- names(unlist(stepMod[[1]])) # get the shortlisted variable.
shortlistedVars <- shortlistedVars[!shortlistedVars %in% "(Intercept)"]  # remove intercept 
print(shortlistedVars)
#The output could includes levels within categorical variables, since ‘stepwise’ is a linear regression based technique, as seen above.

#If you have a large number of predictor variables (100+), the above code may need to be placed in a loop that will run 
#stepwise on sequential chunks of predictors. The shortlisted variables can be accumulated for further analysis towards 
#the end of each iteration. This can be very effective method, if you want to (i) be highly selective about discarding valuable 
#predictor variables. (ii) build multiple models on the response variable.


# with package boruta
############################
#install.packages("Boruta")
library(Boruta)

# Decide if a variable is important or not using Boruta
boruta_output <- Boruta(ozone_reading ~ ., data=na.omit(inputData), doTrace=2)  # perform Boruta search
# Confirmed 10 attributes: Humidity, Inversion_base_height, Inversion_temperature, Month, Pressure_gradient and 5 more.
# Rejected 3 attributes: Day_of_month, Day_of_week, Wind_speed.

boruta_signif <- names(boruta_output$finalDecision[boruta_output$finalDecision %in% c("Confirmed", "Tentative")])  # collect Confirmed and Tentative variables
print(boruta_signif)  # significant variables
#=> [1] "Month"                 "ozone_reading"         "pressure_height"      
#=> [4] "Humidity"              "Temperature_Sandburg"  "Temperature_ElMonte"  
#=> [7] "Inversion_base_height" "Pressure_gradient"     "Inversion_temperature"
#=> [10] "Visibility"
plot(boruta_output, cex.axis=.7, las=2, xlab="", main="Variable Importance")  # plot variable importance

# Information Value and weight evidence
########################################
#The InformationValue package provides convenient functions to compute weights of evidence and information value for categorical variables.#
#Weights of Evidence (WOE) provides a method of recoding a categorical X variable to a continuous variable. For each category of a categorical variable, 
#the WOE is calculated as:
  
  
 # WOE=ln(percentage good of all goodspercentage bad of all bads)

#In above formula, ‘goods’ is same as ‘ones’ and ‘bads’ is same as ‘zeros’.
#Information Value (IV) is a measure of the predictive capability of a categorical x variable to accurately predict the goods and bads. 
#For each category of x, information value is computed as:
  
  #  InformationValuecategory=percentage good of all goods-percentage bad of all badsWOE

#The total IV of a variable is the sum of IV’s of its categories.


library(devtools)
install_github("selva86/InformationValue")

library(InformationValue)
inputData <- read.csv("http://rstatistics.net/wp-content/uploads/2015/09/adult.csv")
head(inputData)

factor_vars <- c ("WORKCLASS", "EDUCATION", "MARITALSTATUS", "OCCUPATION", "RELATIONSHIP", "RACE", "SEX", "NATIVECOUNTRY")  # get all categorical variables
all_iv <- data.frame(VARS=factor_vars, IV=numeric(length(factor_vars)), STRENGTH=character(length(factor_vars)), stringsAsFactors = F)  # init output dataframe
for (factor_var in factor_vars){
  all_iv[all_iv$VARS == factor_var, "IV"] <- InformationValue::IV(X=inputData[, factor_var], Y=inputData$ABOVE50K)
  all_iv[all_iv$VARS == factor_var, "STRENGTH"] <- attr(InformationValue::IV(X=inputData[, factor_var], Y=inputData$ABOVE50K), "howgood")
}

all_iv <- all_iv[order(-all_iv$IV), ] 

for(factor_var in factor_vars){
  inputData[[factor_var]] <- WOE(X=inputData[, factor_var], Y=inputData$ABOVE50K)
}
head(inputData)



##############################
### Statistical tests
##############################
###http://r-statistics.co/Statistical-Tests-in-R.html
# One sample t-test

set.seed(100)
x <- rnorm(50, mean = 10, sd = 0.5)
t.test(x, mu=10) # testing if mean of x could be
#=> One Sample t-test
#=> sample estimates:
#=> mean of x 
#=>  10.04075 


#How to interpret?
#In above case, the p-Value is not less than significance level of 0.05, therefore the null 
#hypothesis that the mean=10 cannot be rejected. Also note that the 95% confidence interval range 
#includes the value 10 within its range. So, it is ok to say the mean of ‘x’ is 10, especially 
#since ‘x’ is assumed to be normally distributed. In case, a normal distribution is not assumed, 
#use wilcoxon signed rank test.
#Note: Use conf.level argument to adjust the confidence level.  

