## ----install, eval=FALSE---------------------------------------------------------------------------------------------
## install.packages("ggplot2") ## for visualisation
## install.packages("survey") ## for probabilistic survey
## install.packages("nonprobsvy") ## lastest version from CRAN
## remove.packages("nonprobsvy")

## ----packages, message = FALSE---------------------------------------------------------------------------------------
library(nonprobsvy)
library(survey)
library(ggplot2)


## ----reading-jvs-----------------------------------------------------------------------------------------------------
jvs <- read.csv("data-raw/jvs.csv",
                colClasses = c("character", "numeric", rep("character", 3), "numeric"))
head(jvs)


## ----svydesign-------------------------------------------------------------------------------------------------------
## survey extracted by the Institute of Informatics and Quantitative Economics of the PUEB.
jvs_svy <- svydesign(ids = ~ 1,  ## stratified sampling (no clustering)
                     weights = ~ weight,  ## final weight
                     strata = ~ size + nace + region, ## stratification variables
                     data = jvs
                     #,calibrate.formula = ~ size + nace + region ## if weights are calibrated to known population sizes in these variables see: https://cran.r-project.org/web/packages/survey/vignettes/precalibrated.pdf
)

svytotal(~size, jvs_svy)


##----data-reading------------------------------------------------------------------------------------------------------
## extracted by the CBOP Central Job Vacancy Database API
admin <- read.csv("data-raw/admin.csv",
                  colClasses = c("character", "numeric", rep("character", 3), "logical")
)
head(admin)

mean(admin$single_shift)


## ----ipw-stadnard----------------------------------------------------------------------------------------------------
est_logit <- nonprob(
  selection = ~ region + private,
  target = ~ single_shift,
  svydesign = jvs_svy,
  data = admin,
  method_selection = "logit"
)

### EX 0 Add nace and size variables to the model - compare the results.

### EX 1 Carry out an analogous inference using probit as the linking function.

### EX 2 Carry out an analogous inference using cloglog as the linking function.

est_ipw_standard <- rbind(cbind(est1_logit$output, est1_logit$confidence_interval),
                          cbind(est1_probit$output, est1_probit$confidence_interval),
                          cbind(est1_cloglog$output, est1_cloglog$confidence_interval))
est_ipw_standard$est <- "ipw"
rownames(est_ipw_standard) <- NULL
est_ipw_standard


## ----ipw-structure---------------------------------------------------------------------------------------------------
str(est1_logit,1)


## ----ipw-structure-sel-----------------------------------------------------------------------------------------------
str(est1_logit$selection,1)


## ----ipw-summary-----------------------------------------------------------------------------------------------------
summary(est1_logit)


## ----ipw-cal---------------------------------------------------------------------------------------------------------
est2_logit <- nonprob(
  selection = ~ region + private + nace + size,
  target = ~ single_shift,
  svydesign = jvs_svy,
  data = admin,
  method_selection = "logit",
  control_selection = controlSel(h = 1, est_method_sel = "gee")
)

### EX 3 Estimate with an another choice for h function.

### EX 4 Change the set of dependent variables and compare the results.

### EX 5 Carry out an analogous inference using probit as the linking function.

### EX 6 Carry out an analogous inference using cloglog as the linking function.

est_ipw_calib <- rbind(cbind(est2_logit$output, est2_logit$confidence_interval),
                       cbind(est2_probit$output, est2_probit$confidence_interval),
                       cbind(est2_cloglog$output, est2_cloglog$confidence_interval))
est_ipw_calib$est <- "ipw calib"
rownames(est_ipw_calib) <- NULL
est_ipw_calib


## ----ipw-cal-weights----------------------------------------------------------------------------------------------------
admin$ipw1_weight <- est1_logit$weights
admin$ipw2_weight <- est2_logit$weights


## ----ipw-cal-totals--------------------------------------------------------------------------------------------------
c(jvs=sum(weights(jvs_svy)), ipw1_mle=sum(admin$ipw1_weight), ipw2_gee=sum(admin$ipw2_weight))


## ----ipw-cal-klasa1--------------------------------------------------------------------------------------------------
svytotal(~size, jvs_svy)


## ----ipw-cal-klasa2--------------------------------------------------------------------------------------------------
xtabs(ipw1_weight ~ size, admin)
xtabs(ipw2_weight ~ size, admin)


## ----ipw-bootstrap---------------------------------------------------------------------------------------------------
### EX 7 Estimate the mean using the inverse probability weighting method with the bootstrap method for variance.
### In addition, try playing with the number of iterations and arguments
set.seed(2024-11-27)

est3_logit$output

## ----ipw-bootstrap-summary-------------------------------------------------------------------------------------------
summary(est3_logit)


## ----ipw-scad--------------------------------------------------------------------------------------------------------
### EX 8 Conduct inference with an additional variable selection step, e.g. SCAD
set.seed(2024-11-27)


## ----ipw-scad-summary------------------------------------------------------------------------------------------------
summary(est4_logit)


## ----ipw-comparison---------------------------------------------------------------------------------------------------
ipw_summary <- rbind(cbind(est1_logit$output, est1_logit$confidence_interval),
                     cbind(est2_logit$output, est2_logit$confidence_interval),
                     cbind(est3_logit$output, est3_logit$confidence_interval),
                     cbind(est4_logit$output, est4_logit$confidence_interval))
rownames(ipw_summary) <- NULL
ipw_summary$est <- c("ipw (st)", "ipw (cal)", "ipw (boot)", "ipw (scad)")
ipw_summary


## ----mi-glm-lp-------------------------------------------------------------------------------------------------------
est5_glm <- nonprob(
  outcome = single_shift ~ region + private + nace + size,
  svydesign = jvs_svy,
  data = admin,
  method_outcome = "glm",
  family_outcome = "gaussian"
)

cbind(est5_glm$output,est5_glm$confidence_interval)


## ----mi-glm-binom----------------------------------------------------------------------------------------------------
### EX 9 Use a binomial model instead of a Gaussian model for the single_shift variable
cbind(est5_glm_biom$output,est5_glm_biom$confidence_interval)


## ----mi-glm-binom-summary--------------------------------------------------------------------------------------------
summary(est5_glm_biom)


## ----mi-glm-binom-structure------------------------------------------------------------------------------------------
str(est5_glm_biom,1)


## ----mi-glm-nn-------------------------------------------------------------------------------------------------------
### EX 10 Use another mass imputation method - NN - in addition the number of neighbours (k) can be dealt with
cbind(est6_glm_nn$output,est6_glm_nn$confidence_interval)


## ----mi-glm-pmm-1----------------------------------------------------------------------------------------------------
### EX 11 Use another mass imputation method - PMM - in addition the number of neighbours (k) can be dealt with
set.seed(2024-11-27)
cbind(est6_glm_pmm1$output, est6_glm_pmm1$confidence_interval)


## ----mi-glm-pmm-2----------------------------------------------------------------------------------------------------
set.seed(2024-11-27)

cbind(est6_glm_pmm2$output, est6_glm_pmm2$confidence_interval)


## ----mi-glm-scad-----------------------------------------------------------------------------------------------------
### EX 12 Add an additional variable selection step, e.g. SCAD
set.seed(2024-11-27)

## ----mi-glm-scad-result-----------------------------------------------------------------------------------------------
cbind(est7_glm_sel$output,est7_glm_sel$confidence_interval)

## ----mi-glm-scad-summary---------------------------------------------------------------------------------------------
summary(est7_glm_sel)


## ----mi-summary--------------------------------------------------------------------------------------------------
mi_summary <- rbind(cbind(est5_glm$output, est5_glm$confidence_interval),
                    cbind(est5_glm_biom$output, est5_glm_biom$confidence_interval),
                    cbind(est6_glm_nn$output, est6_glm_nn$confidence_interval),
                    cbind(est6_glm_pmm1$output, est6_glm_pmm1$confidence_interval),
                    cbind(est6_glm_pmm2$output, est6_glm_pmm2$confidence_interval),
                    cbind(est7_glm_sel$output, est7_glm_sel$confidence_interval))
rownames(mi_summary) <- NULL
mi_summary$est <- c("mi (lm)", "mi (glm)", "mi (nn)", "mi (pmm1)", "mi (pmm2)", "mi (glm, scad)")
mi_summary


## ----dr-glm-binom----------------------------------------------------------------------------------------------------
est8_dr1 <- nonprob(
  selection = ~ region + private + nace + size,
  outcome = single_shift ~ region + private + nace + size,
  svydesign = jvs_svy,
  data = admin,
  method_selection = "logit",
  method_outcome = "glm",
  family_outcome = "binomial",
  pop_size = sum(weights(jvs_svy))
)

cbind(est8_dr1$output,est8_dr1$confidence_interval)

## ----dr-glm-binom-summary--------------------------------------------------------------------------------------------
summary(est8_dr1)


## ----dr-glm-binom-structure------------------------------------------------------------------------------------------
str(est8_dr1,1)


## ----dr-glm-calib----------------------------------------------------------------------------------------------------
### EX 13 Use a calibration method for inverse probability weighting part
cbind(est8_dr2$output,est8_dr2$confidence_interval)


## ----dr-glm-bootstrap------------------------------------------------------------------------------------------------
### EX 14 Use a bootstrap variance for DR estimator
set.seed(2024-11-27)
cbind(est8_dr3$output,est8_dr3$confidence_interval)


## ----dr-glm-scad-----------------------------------------------------------------------------------------------------
### EX 15 Add an additional variable selection step, e.g. SCAD
set.seed(2024-11-27)
cbind(est9_dr1$output,est9_dr1$confidence_interval)


## ----dr-glm-scad-bias-min--------------------------------------------------------------------------------------------
### EX 16 Add an additional variable selection step, e.g. SCAD and estimate using bias minimization approach
set.seed(2024-11-27)
cbind(est9_dr2$output,est9_dr2$confidence_interval)


## ----dr-summary-------------------------------------------------------------------------------------------------
dr_summary <- rbind(cbind(est8_dr1$output, est8_dr1$confidence_interval),
                    cbind(est8_dr2$output, est8_dr2$confidence_interval),
                    cbind(est8_dr3$output, est8_dr3$confidence_interval),
                    cbind(est9_dr1$output, est9_dr1$confidence_interval),
                    cbind(est9_dr2$output, est9_dr2$confidence_interval))
rownames(dr_summary) <- NULL
dr_summary$est <- c("dr (ipw)", "dr (ipw cal)", "dr (ipw, boot)", "dr (scad)", "dr (scad, min)")
dr_summary


## ----summary-plot------------------------------------------------------------------------------------------------
results <- rbind(ipw_summary, mi_summary, dr_summary)

ggplot(data = results, aes(y = est, x = mean, xmin = lower_bound, xmax = upper_bound)) +
  geom_point() +
  geom_vline(xintercept = mean(admin$single_shift), linetype = "dotted", color = "red") +
  geom_errorbar() +
  labs(x = "Point estimator and confidence interval", y = "estimators")

