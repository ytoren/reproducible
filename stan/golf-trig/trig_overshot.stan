data {
  int<lower=0> N;
  int n[N];
  vector[N] x;
  int y[N];
  real r;
  real R;
  real overshot;
  real distance_tolerance;
}

transformed data {
  vector[N] threshold_angle = asin((R - r) ./ x);
  vector[N] raw_proportions = to_vector(y) ./ to_vector(n);
}

parameters {
  real<lower=0> sigma_angle;
  real<lower=0> sigma_distance;
  real<lower=0> sigma_y;
}

transformed parameters{
  vector[N] p_angle = 2*Phi(threshold_angle / sigma_angle) - 1;
  vector[N] p_upper = Phi((distance_tolerance - overshot) ./ ((x + overshot)*sigma_distance));
  vector[N] p_lower = Phi((- overshot) ./ ((x + overshot) * sigma_distance));
  vector[N] p = p_angle .* (p_upper - p_lower);
}

model {
  raw_proportions ~ normal(p, sqrt(p .* (1-p) ./to_vector(n) + sigma_y^2));
  y ~ binomial_logit(n, p);
  [sigma_angle, sigma_distance, sigma_y] ~ normal(0,1);
}

generated quantities {
  real sigma_degrees = sigma_angle * 180 / pi();
}
