data {
  int<lower=0> obs;
  vector[obs] population;
  int sightings[obs];
}

parameters {
  real alpha;
  real beta;
  real phi;
}

transformed parameters {
  vector<lower = 0>[obs] mu;
  mu = alpha + beta * population;
}

model {
  alpha ~ normal(0, 1);
  beta ~ normal(0, 1);
  phi ~ cauchy(0, 2.5);
  
  sightings ~ neg_binomial_2(mu, phi);
  
}

generated quantities {
  vector[obs] sightings_pred;
  vector[obs] log_lik;
  
  for (i in 1:obs) {
    log_lik[i] = neg_binomial_2_lpmf(sightings[i] | mu[i], phi);
    sightings_pred[i] = neg_binomial_2_rng(mu[i], phi);
  }
}
