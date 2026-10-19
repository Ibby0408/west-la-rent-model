## =============================================================
## STAT 101A Final Project - Data Description Section
## Rental Price Near UCLA
##
## This script reproduces every number, table, and figure reported
## in the Data Description section of the final report, starting
## from the raw merged RentCast dataset (rentcast_ucla_rentals_15zips_full.csv,
## 2,519 listings x 16 fields, collected separately via the RentCast API
## for 15 zip codes surrounding UCLA).
## =============================================================

library(dplyr)
library(car)     # for vif()

## -------------------------------------------------------------
## 1. Read raw merged data + basic QC
## -------------------------------------------------------------
data <- read.csv("rentcast_ucla_rentals_15zips_full.csv")

# Confirm the zipCode RentCast returned matches the zip code we searched for
mismatch <- data %>% filter(as.character(zipCode) != as.character(search_zip))
nrow(mismatch)
table(mismatch$search_zip, mismatch$zipCode)

## -------------------------------------------------------------
## 2. Variable selection
## -------------------------------------------------------------
# Keep the 6 core variables + zipCode, plus latitude/longitude
# (kept temporarily to test as an alternative to zipCode -- see Step 4)
data_clean <- data %>%
  select(price, zipCode, bedrooms, bathrooms, squareFootage,
         propertyType, yearBuilt, latitude, longitude)

str(data_clean)
colSums(is.na(data_clean))

data_clean$zipCode <- as.factor(data_clean$zipCode)
data_clean$propertyType <- as.factor(data_clean$propertyType)

## -------------------------------------------------------------
## 3. Handle missing data and rare categories
## -------------------------------------------------------------
# yearBuilt is missing for 31.6% of listings (795/2,519) -- too much
# structural missingness to keep or impute responsibly. Drop the variable.
data_clean2 <- data_clean %>% select(-yearBuilt)

# bathrooms (2 missing) and squareFootage (273 missing) are core variables
# that cannot be reasonably imputed -- remove those rows.
data_clean2 <- data_clean2 %>%
  filter(!is.na(bathrooms), !is.na(squareFootage))

nrow(data_clean2)
colSums(is.na(data_clean2))
table(data_clean2$zipCode)

# propertyType: "Multi-Family" has only 3 observations, too few to
# reliably estimate its effect -- remove and drop the empty level.
table(data_clean2$propertyType)

data_clean3 <- data_clean2 %>%
  filter(propertyType != "Multi-Family") %>%
  droplevels()

nrow(data_clean3)
table(data_clean3$propertyType)
table(data_clean3$zipCode)

## -------------------------------------------------------------
## 4. Test latitude/longitude as an alternative to zipCode
## -------------------------------------------------------------
data_clean3$zipCode <- as.factor(data_clean3$zipCode)
data_clean3$propertyType <- as.factor(data_clean3$propertyType)

full_model_geo <- lm(price ~ zipCode + bedrooms + bathrooms + squareFootage +
                       propertyType + latitude + longitude,
                     data = data_clean3)
summary(full_model_geo)
vif(full_model_geo)   # latitude/longitude show VIF = 11.4, 18.0 -- highly
# collinear with zipCode

reduced_model_nogeo <- lm(price ~ zipCode + bedrooms + bathrooms + squareFootage +
                            propertyType,
                          data = data_clean3)

# Partial F-test: does latitude/longitude add explanatory power beyond zipCode?
anova(reduced_model_nogeo, full_model_geo)
# Statistically significant (p = 0.002) but a very small effect size
# (RSS drops by only ~0.55%) -- driven mainly by large sample size.
# Decision: drop latitude/longitude, keep zipCode alone for interpretability.

## -------------------------------------------------------------
## 5. Generate near-final dataset (drop latitude/longitude)
## -------------------------------------------------------------
final_clean <- data_clean3 %>%
  select(-latitude, -longitude)

str(final_clean)
nrow(final_clean)
colnames(final_clean)
colSums(is.na(final_clean))
table(final_clean$zipCode)
table(final_clean$propertyType)

## -------------------------------------------------------------
## 6. Additional data-quality check: squareFootage / price-per-sqft
## -------------------------------------------------------------
sum(final_clean$squareFootage == 0)
final_clean[final_clean$squareFootage == 0, ]

final_clean$price_per_sqft <- final_clean$price / final_clean$squareFootage
summary(final_clean$price_per_sqft)
sum(is.infinite(final_clean$price_per_sqft))
sum(final_clean$price_per_sqft < 1, na.rm = TRUE)
sum(final_clean$price_per_sqft > 20, na.rm = TRUE)

# Remove: squareFootage = 0 (1 obs), price/sqft < $1 (26 obs) -- implausible,
# consistent with data entry errors (same threshold used in Mini Assignment 2)
final_clean_low <- final_clean %>%
  filter(squareFootage > 0, price_per_sqft >= 1)
nrow(final_clean_low)

# Inspect the high end before deciding
final_clean_low %>%
  filter(price_per_sqft > 20) %>%
  select(price, squareFootage, price_per_sqft, zipCode, propertyType)
# 2 listings with implausibly small squareFootage relative to price
# (e.g., a 78 sq ft "apartment") -- remove as data entry errors.

final_clean_final <- final_clean_low %>%
  filter(price_per_sqft <= 20) %>%
  select(-price_per_sqft)

nrow(final_clean_final)   # 2,212 observations -- final analytic sample
str(final_clean_final)

write.csv(final_clean_final, "rentcast_ucla_rentals_clean_final.csv", row.names = FALSE)

## =============================================================
## DATA DESCRIPTION -- tables and figures reported in the report
## =============================================================
final_clean_final <- read.csv("rentcast_ucla_rentals_clean_final.csv")
final_clean_final$zipCode <- as.factor(final_clean_final$zipCode)
final_clean_final$propertyType <- as.factor(final_clean_final$propertyType)

cont_vars <- final_clean_final[, c("price", "bedrooms", "bathrooms", "squareFootage")]

## ---- Summary statistics (reported in main report) ----
summary_table <- data.frame(
  Variable = names(cont_vars),
  Min      = sapply(cont_vars, min),
  Q1       = sapply(cont_vars, quantile, 0.25),
  Median   = sapply(cont_vars, median),
  Mean     = sapply(cont_vars, mean),
  Q3       = sapply(cont_vars, quantile, 0.75),
  Max      = sapply(cont_vars, max),
  SD       = sapply(cont_vars, sd)
)
print(summary_table, row.names = FALSE)

## ---- Categorical distributions (Appendix Table A1) ----
table(final_clean_final$zipCode)
table(final_clean_final$propertyType)

## ---- Mean price by zip code (Appendix Table A2) ----
tapply(final_clean_final$price, final_clean_final$zipCode, mean)

## ---- Correlation matrix (Appendix Table A3) ----
cor(cont_vars)

## ---- Figure (main report): price by zip code and property type, combined ----
jpeg("fig_price_by_categorical.jpg", width = 1000, height = 450)
par(mfrow = c(1, 2))
boxplot(price ~ zipCode, data = final_clean_final,
        main = "Rental Price by Zip Code",
        xlab = "Zip Code", ylab = "Price ($)",
        las = 2, cex.axis = 0.6)
boxplot(price ~ propertyType, data = final_clean_final,
        main = "Rental Price by Property Type",
        xlab = "Property Type", ylab = "Price ($)")
par(mfrow = c(1, 1))
dev.off()

## ---- Figure A1 (Appendix): price distribution histogram ----
jpeg("fig1_price_histogram.jpg", width = 800, height = 500)
hist(final_clean_final$price,
     main = "Distribution of Monthly Rental Price",
     xlab = "Price ($)", col = "lightblue", breaks = 40)
dev.off()

## ---- Figure A2 (Appendix): scatterplot matrix ----
jpeg("fig_scatter_matrix.jpg", width = 700, height = 700)
pairs(~ price + bedrooms + bathrooms + squareFootage, data = final_clean_final,
      main = "Scatter Plot Matrix", pch = 1, cex = 0.5)
dev.off()
