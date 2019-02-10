## From: https://codingclubuc3m.rbind.io/post/2019-01-22/

library('rstan')
library('dplyr')
library('magrittr')


# Bernoulli ---------------------------------------------------------------
theta = 0.3
N = 20
y = rbinom(N, 1, theta)
y
sum(y) / N

ber_post = stan(file = 'git/reproducible/rstan-tutorial/Bernoulli.stan', data = list(y=y,N=N), iter=5000)

print(ber_post, probs = c(0.1, 0.9))

## Extract draws
ber_post %>%
  rstan::extract() %>% 
  .$theta %>% 
  mean()

ber_post %>%
  rstan::extract() %>% 
  .$theta -> theta_draws

theta_draws %>% 
  tibble(theta = .) %>% 
  ggplot(aes(x = theta)) + geom_histogram()


# MAP / MLE ---------------------------------------------------------------
N = 5
y = c(0, 1, 1, 0, 0)

stan_model(file = 'git/reproducible/rstan-tutorial/Bernoulli.stan') %>% 
  optimizing(., data = c('N', 'y')) %>% 
  print(digits = 2)



# Lotka-Voltera model -----------------------------------------------------
## https://mc-stan.org/users/documentation/case-studies/lotka-volterra-predator-prey.html
file = "https://raw.githubusercontent.com/stan-dev/example-models/master/knitr/lotka-volterra/hudson-bay-lynx-hare.csv"
# https://github.com/bblais/Systems-Modeling-Spring-2015-Notebooks/blob/master/data/Lynx%20and%20Hare%20Data/lynxhare.csv

lynx_hare_df = read.csv(file, header=TRUE, comment.char="#") %>% as_tibble()

N = dim(lynx_hare_df)[1] - 1
ts = 1:N
y_init = c(lynx_hare_df$Hare[1], lynx_hare_df$Lynx[1])
y = as.matrix(lynx_hare_df[2:(N + 1), 2:3])
y = cbind(y[, 2], y[, 1]); # hare, lynx order
lynx_hare_data = list(N, ts, y_init, y)

LV_post <- stan(
  file = 'git/reproducible/rstan-tutorial/Lotka-Voltera.stan', 
  data=lynx_hare_data, 
  iter=5000, chains=3, cores=3
  )

LV_post %>% 
  print(
    pars=c("theta", "sigma", "z_init"),
    probs=c(0.1, 0.5, 0.9),
    digits = 3
  )
