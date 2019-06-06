data {
  int<lower=0> obs;
  vector[obs] population;
  vector[obs] sightings;
}

parameters {
  real alpha;
  real beta;
  real<lower=0> sigma;
}

transformed parameters {
  vector<lower = 0>[obs] mu;
  mu = alpha + beta * population;
}

model {
  alpha ~ normal(0, 5);
  beta ~ normal(0, 5);
  sigma ~ cauchy(0, 2.5);

  sightings ~ normal(mu, sigma);
  
}

generated quantities {
  vector[obs] sightings_pred;
  vector[obs] log_lik;
  
  for (i in 1:obs) {
    log_lik[i] = normal_lpdf(sightings[i] | mu[i], sigma);
    sightings_pred[i] = normal_rng(mu[i], sigma);
  }
}
