data {
  int<lower=0> N;
  int n[N];
  vector[N] x;
  int y[N];
  real r;
  real R;
}

transformed data {
  vector[N] threshold_angle = asin((R - r) ./ x);
}

parameters {
  real<lower=0> sigma;
}

transformed parameters{
  vector[N] p = 2 * Phi(threshold_angle / sigma) - 1;
}

model {
  y ~ binomial_logit(n, p);
}

generated quantities {
  real sigma_degrees = sigma * 180 / pi();
}
