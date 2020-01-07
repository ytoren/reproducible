data {
  int<lower=1> obs;
  vector<lower=0>[obs] population;
  int<lower=0> sightings[obs];
}

parameters {
  real alpha;
  real beta;
}

transformed parameters {
  vector<lower = 0>[obs] mu;
  mu = alpha + beta * population;
}

model {
  alpha ~ normal(0,1);
  beta ~ normal(0,1);
  sightings ~ poisson(mu);
}

generated quantities {
  int<lower=0> sightings_pred[obs];
  vector[obs] log_lik;
  
  for (i in 1:obs) {
    log_lik[i] = poisson_lpmf(sightings[i] | mu[i]);
    sightings_pred[i] = poisson_rng(mu[i]);
  }
}
