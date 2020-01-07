data {
  int<lower=0> n_obs; // number of rows
  int<lower=0> n_states; // number of states
  int<lower=0> state[n_obs]; // state (coded as INTs)
  vector<lower=0>[n_obs] population;
  int<lower=0> sightings[n_obs];
}

parameters {
  real alpha[n_states];
  real alpha_mu;
  real<lower=0> alpha_sd;

  real beta;
  real<lower=0> phi;
}

transformed parameters {
  vector<lower = 0>[n_obs] mu;
  for (i in 1:n_obs) {
    mu[i] = alpha[state[i]] + beta * population[i];
  }
}

model {
  alpha_mu ~ normal(0, 1);
  alpha_sd ~ cauchy(0, 2);
  beta ~ normal(0, 1);
  phi ~ cauchy(0, 2.5);

  alpha ~ normal(alpha_mu, alpha_sd);
  sightings ~ neg_binomial_2_log(mu, phi);
}

generated quantities {
  vector[n_obs] sightings_pred;
  vector[n_obs] log_lik;
  
  for (i in 1:n_obs) {
    log_lik[i] = neg_binomial_2_log_lpmf(sightings[i] | mu[i], phi);
    sightings_pred[i] = neg_binomial_2_log_rng(mu[i], phi);
  }
}
