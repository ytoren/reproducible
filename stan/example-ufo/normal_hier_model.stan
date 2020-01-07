data {
  int<lower=0> n_obs; // number of rows
  int<lower=0> n_states; // number of states
  int<lower=0> state[n_obs]; // state (coded as INTs)
  vector<lower=0>[n_obs] population;
  vector<lower=0>[n_obs] sightings;
}

parameters {
  real alpha_state[n_states];
  real alpha_mu;
  real<lower=0> alpha_sd;
  
  real beta;
  real<lower=0> sigma;
}

transformed parameters {
  vector<lower = 0>[n_obs] mu;
  for (i in 1:n_obs) {
    mu[i] = alpha_mu + alpha_state[state[i]] + beta * population[i];
  }
}

model {
  alpha_mu  ~ normal(0, 1);
  alpha_sd  ~ cauchy(0, 2.5);
  beta      ~ normal(0, 1);
  sigma     ~ cauchy(0, 2.5);

  alpha_state ~ normal(0, alpha_sd);
  sightings   ~ normal(mu, sigma);
}

generated quantities {
  vector[n_obs] log_lik;
  vector[n_obs] sightings_pred;
  
  for (i in 1:n_obs) {
    log_lik[i] = normal_lpdf(sightings[i] | mu[i], sigma);
    sightings_pred[i] = normal_rng(mu[i], sigma);
  }
}
