## FROM: https://www.weirddatascience.net/index.php/2019/04/08/bayes-vs-the-invaders-part-two-abnormal-distributions/
## FROM: https://www.weirddatascience.net/index.php/2019/04/17/bayes-vs-the-invaders-part-three-the-parallax-view/
library('tidyverse')
library('tidybayes')
library('rstan')
library('bayesplot')
library('loo')

file_path <- 'data/'
joined_file <- 'population_sighting_by_year.csv'
# min_chain = 1000
post_sample_n <- 100 # for showing posterior dist 
start_date <- as.Date('1970-01-01')

# Data --------------------------------------------------------------------
d <- read_csv(paste0(file_path, joined_file)) %>% 
  filter(date >= start_date) %>% 
  drop_na()

stan_data <- list(
  obs = dim(d)[1],
  population = d %>% pull(population),
  sightings = d %>% pull(n)
)


# Poisson model -------------------------------------------------------
stan_poisson <- stan(file = 'poisson_model.stan', data = stan_data, cores = 4)

## diagnostics 
stan_poisson %>% traceplot(pars = c('alpha', 'beta'), ncol = 1)

## posterior dist
stan_poisson %>% 
  summary(pars = c('alpha', 'beta')) %>% 
  .['summary']

## model fit
stan_plot_overlay(stan_poisson, 'sightings_pred', y = d %>% pull(n))
stan_plot_model_fit(stan_poisson, par = 'mu', population = d$population, sightings = d$n)


# Poisson-log model -------------------------------------------------------
stan_poisson_log <- stan(file = 'poisson_log_model.stan', data = stan_data, cores = 4)

## diagnostics 
stan_poisson_log %>% traceplot(pars = c('alpha', 'beta'), ncol = 1)

## posterior dist
stan_poisson_log %>% 
  summary(pars = c('alpha', 'beta')) %>% 
  .['summary']

## model fit
stan_plot_overlay(stan_poisson_log, 'sightings_pred', y = d %>% pull(n))
stan_plot_model_fit(stan_poisson_log, par = 'mu', population = d$population, sightings = d$n)

# Normal model --------------------------------------------------------
stan_normal <- stan(file = 'normal_model.stan', data = stan_data, cores = 4)

## diagnostics 
stan_normal %>% traceplot(pars = c('alpha', 'beta', 'sigma'), ncol = 1)

## posterior dist
stan_normal %>% 
  summary(pars = c('alpha', 'beta', 'sigma')) %>% 
  .['summary']

stan_plot_overlay(stan_normal, 'sightings_pred', y = d %>% pull(n))
stan_plot_model_fit(stan_normal, par = 'mu', population = d$population, sightings = d$n)



# Negative Bonimoal -------------------------------------------------------
stan_nb <- stan(file = 'neg_binomial_model.stan', data = stan_data, cores = 4)

## diagnostics 
stan_nb %>% traceplot(pars = c('alpha', 'beta', 'phi'), ncol = 1)

## posterior dist
stan_nb %>% 
  summary(pars = c('alpha', 'beta', 'phi')) %>% 
  .['summary']

stan_plot_overlay(stan_nb, 'sightings_pred', y = d %>% pull(n))
stan_plot_model_fit(stan_nb, par = 'mu', population = d$population, sightings = d$n)


# Model Comparison --------------------------------------------------------
compare(stan_loo(stan_normal), stan_loo(stan_poisson))
compare(stan_loo(stan_poisson), stan_loo(stan_poisson_log))

compare(stan_loo(stan_normal), stan_loo(stan_nb))
compare(stan_loo(stan_poisson_log), stan_loo(stan_nb))

