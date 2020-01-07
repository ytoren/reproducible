data {
  int N;
  int x[N];
  int offset;
}

transformed data {
  int y[N];
  for (n in 1:N)
    y[n] = x[n] - offset
}

parameters {
  real<lower=0> lambda1;
  real<lower=0> lambda2;
}

transformed parameters {
  real<lower=0> lambda;
  lambda = lambda1 + lambda2;
}

model {
  lambda1 ~ cauchy(0, 0.25);
  lambda2 ~ cauchy(0, 0,25);
  
  y ~ poisson(lambda);
}

generated quantities {
  int x_predict;
  x_predict = poission_rng(lambda) + offset;
}

