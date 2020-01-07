
# Sample rows from posterior chains ---------------------------------------
stan_sample_post_chains <- function(s, size = 100, seed = 1234) {
  set.seed(seed)
  
  s@stan_args %>% 
    sapply(as_tibble) %>% 
    t() %>% 
    as.data.frame() %>%
    mutate(samples = as.numeric(iter) - as.numeric(warmup)) %>% 
    pull(samples) %>% 
    sum() %>% 
    1:. %>% 
    sample(size = size) %>% 
    return()
}

stan_extract_post_chains <- function(s, par, sample = NULL) {
  m <- as.matrix(s, pars = par)
  
  if (is.null(sample)) {
    return(m)
  } else {
    return(m[sample,])
  }
}


# LOO ---------------------------------------------------------------------
stan_loo <- function(s, cores = 4) {
  LL <- s %>% extract_log_lik(merge_chains = FALSE)
  RE <- LL %>% exp() %>% relative_eff()
  RE[is.nan(RE)] <- 0
  return(loo(LL, r_eff = RE, cores = cores))
}


# Plot model fit ----------------------------------------------------------
stan_plot_model_fit <- function(s, par, population, sightings, logx = FALSE, logy = FALSE) {
  g <- s %>% 
    summary(pars = par) %>% 
    .[[1]] %>% 
    as_tibble() %>% 
    mutate(population = population, sightings = sightings) %>% 
    ggplot() %>% 
      +geom_point(aes(x = population, y = sightings), colour = '#0b6788', alpha = 0.1, size = 0.5) %>% 
      +geom_line(aes(x = population, y = mean), colour = '#3cd070') %>%
      +geom_ribbon(aes(x = population, ymin = `2.5%`, ymax = `97.5%`), alpha = 0.2, fill = "#3cd070")
  
  if (logx) {g <- g + scale_x_log10()}
  if (logy) {g <- g + scale_y_log10()}
  
  return(g)
}

stan_plot_overlay <- function(s, par, y, alpha = 0.4) {
  ppc_dens_overlay(
    y = y, #actual dist
    yrep = stan_extract_post_chains(
      s = s, 
      par = par, 
      sample = stan_sample_post_chains(s)
    ),
    alpha = alpha
  ) 
}