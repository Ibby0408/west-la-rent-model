# West LA Rental Price Model

A multiple linear regression model of monthly rent for 2,200+ listings across 15 ZIP codes near UCLA. Course project for UCLA Stats 101A. Built in R.

**Full report:** [`Stats101A_Final_Report.pdf`](Stats101A_Final_Report.pdf)

## Question

How is monthly rent near UCLA associated with unit size, bedrooms, bathrooms, property type, and ZIP code? Can a model give renters a benchmark for whether a listing is fairly priced?

## Data

- Active long-term rental listings pulled from the **RentCast API**
- 2,519 raw listings → **2,211** after cleaning
- 15 ZIP codes; variables: price, ZIP code, bedrooms, bathrooms, square footage, property type (Apartment, Condo, Single Family, Townhouse)
- The raw data is not included in this repo. It can be re-pulled from the RentCast API.

**Cleaning decisions**

- Dropped `yearBuilt` (31.6% missing) and non-informative fields (ID, address, etc.)
- Tested latitude/longitude as an alternative to ZIP code, but they were highly collinear with it (VIF = 11.4 and 18.0), so ZIP code stayed for interpretability
- Removed listings missing square footage or bathrooms, the Multi-Family category (n = 3, too few to estimate), and implausible price-per-sq-ft values (below $1 or above $20)
- Removed one physically impossible listing (14 bedrooms and 8 bathrooms in 125 sq ft)

## Methods

1. **Baseline model.** An untransformed regression had R² = 0.78, but diagnostics showed curvature, increasing residual variance, and heavy tails.
2. **Response transformation.** The inverse response plot suggested λ ≈ 0.6 and Box-Cox suggested λ ≈ 0, so I compared square-root and log. Log(price) gave more stable residuals and had direct Box-Cox support.
3. **Predictor transformation.** Residual plots showed remaining curvature in square footage. I compared log vs. square-root square footage with AIC/BIC, and the square-root model won clearly (AIC 336 vs. 426, BIC 461 vs. 551).
4. **Variable selection.** Forward and backward stepwise selection on AIC kept every predictor.
5. **Diagnostics.** Adjusted GVIFs were about 2 or lower, so there was no serious multicollinearity. 28 points had |standardized residual| > 3, but the max Cook's distance was only 0.022, so no observation was removed.

**Final model:** `log(price) ~ ZIP + bedrooms + bathrooms + sqrt(squareFootage) + propertyType`

## Key results

The final model explains about **81% of the variation in log rent** (R² = 0.807, adjusted R² = 0.805, F(20, 2190) = 456.9, p < 0.001).

| Predictor | Estimated association with rent (holding others fixed) |
|---|---|
| Square footage | +4.1% per 1-unit increase in sqrt(sq ft); diminishing returns as units get larger |
| Bathroom | +5.8% per additional bathroom |
| Bedroom | +3.9% per additional bedroom |
| Property type (vs. Apartment) | Condo +19.5%, Single Family +18.4%, Townhouse +13.3% |
| Location (vs. ZIP 90019) | Largest premium in 90069 (West Hollywood), about +62% |

Location and property type matter even after controlling for size, which fits what you would expect in the West LA market.

## Limitations

- Some heteroscedasticity, non-normality in the tails, and slight nonlinearity remain in the residuals
- The model has no information on building age, amenities, parking, in-unit laundry, or renovation quality
- Results describe asking rents in listings, not final signed rents
- Possible future work: more predictors and interaction terms

## Files

- `Stats101A_Final_Report.pdf`: full write-up with tables, diagnostics, and appendix

## Credits

Team project for UCLA Stats 101A. Team members: Zirui Zhai, Ibrahim Ahmad, Zelin Chen, Lucas Lam, Fei Peng
