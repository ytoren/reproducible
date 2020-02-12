## FROM: https://mc-stan.org/users/documentation/case-studies/golf.html
library(rvest)
library(ggplot2)
library(dplyr)
library(magrittr)
library(rstan)
library(tidybayes)

rstan_options(auto_write=FALSE)
options(mc.cores=parallel::detectCores())


# Scrape data -------------------------------------------------------------
url <- 'https://statmodeling.stat.columbia.edu/2019/03/21/new-golf-putting-data-and-a-new-golf-putting-model'

raw_data <- url %>%
  read_html() %>% 
  html_nodes(xpath='/html/body/div/div[3]/div/div[1]/div[3]/div[2]/pre[1]') %>% 
  html_text()

d <- raw_data %>% 
  textConnection() %>%
  read.table(header = TRUE)

d <- d %>% 
  mutate(p = y / n, sd = sqrt(p * (1 - p) / n))


# Graph 1 ----------------------------------------------------------
p1 <- d %>% 
  ggplot(aes(x = x, y = p)) %>% 
  +geom_errorbar(aes(ymin = p - sd, ymax = p + sd), width = 0.1, lwd = 0.5) %>% 
  +geom_point() %>% 
  +ylim(0,1) + xlim(0, 20) + xlab('Distanct from hole (feet)') + ylab('Probability of hit')

show(p1)


# Logistic Model ----------------------------------------------------------
golf_data <- with(d, list(x=x, y=y, n=n, N=dim(d)[1]))
fit_logistic <- stan("stan/golf-trig/logistic.stan", data=golf_data)
a_sim <- extract(fit_logistic, 'a')[[1]]
b_sim <- extract(fit_logistic, 'b')[[1]]


# Graph 2 -----------------------------------------------------------------
generate_logit <- function(a, b) {function(x) {1 / (1+exp(-1 * (a + b * x)))}}
set.seed(1234)
samples <- sample(x = length(a_sim), size = 100, replace = FALSE)

p2 <- p1 + stat_function(fun = generate_logit(median(a_sim), median(b_sim)), color = 'black', lwd = 0.3)
for (s in samples) {
  # print(c(a_sim[s], b_sim[s]))
  p2 <- p2 + stat_function(fun = generate_logit(a_sim[s], b_sim[s]), color = 'green', lwd = 0.1)
}

show(p2)

d %>% 
  data_grid(x = seq_range(x, n = 20)) %>% 
  add_fitted_draws(model = fit_logistic)

# Trig based model -----------------------------------------------------
r <- (1.68/2)/12
R <- (4.25/2)/12

fit_trig <- stan(file = "stan/golf-trig/trig.stan", data=c(golf_data, r=r, R=R))

print(fit_trig, pars = c('sigma', 'sigma_degrees'))

sigma_sim <- extract(fit_trig, 'sigma')[[1]]
sigma_degrees_sim <- extract(fit_trig, 'sigma_degrees')[[1]]

generate_trig <- function(sigma) {function(x) {2 * pnorm(asin((R - r) / x) / sigma) - 1}}

p3 <- p1 + 
  stat_function(fun = generate_logit(mean(a_sim), mean(b_sim)), color = 'black', lwd = 0.3) + 
  stat_function(fun = generate_trig(mean(sigma_sim)),  color = 'blue',  lwd = 0.3) 

show(p3)  


# Aug Trig model ----------------------------------------------------------
fit_trig_aug <- stan(
  file = "stan/golf-trig/trig_overshot.stan", 
  data=c(golf_data, r=r, R=R, overshot = 1., distance_tolerance = 3.)
)

print(fit_trig_aug, pars = c('sigma_distance', 'sigma_angle', 'sigma_degrees', 'sigma_y'))


# Residuals ---------------------------------------------------------------
d %>% 
  mutate(
    p_mean = apply(X = extract(fit_trig_aug, 'p')[[1]], MARGIN = 2, FUN = mean),
    p_sd = apply(X = extract(fit_trig_aug, 'p')[[1]], MARGIN = 2, FUN = sd)
  ) %>% 
  ggplot(aes(x = x)) %>% 
  +geom_errorbar(aes(ymin = p_mean - p_sd, ymax = p_mean + p_sd)) %>% 
  +geom_point(aes(y = p_mean), colour = 'blue') %>%
  +geom_point(aes(y = p), colour = 'black')

d %>% 
  mutate(
    p_mean = apply(X = extract(fit_trig_aug, 'p')[[1]], MARGIN = 2, FUN = mean),
    res = p - p_mean
  ) %>% 
  ggplot(aes(x = x, y = res)) + geom_point()
