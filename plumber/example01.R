
## From: https://rviews.rstudio.com/2018/07/23/rest-apis-and-plumber/

library(plumber)

#* apiTitle Test API

#* Echo provided text
#* @param txt The response text
#* @get /echo
#* @post /echo
function (req, txt ='', number = 0) {
  error = ''
  if (is.na(as.numeric(number))) {
    error = 'non numeric values for number'
    number = NA
  }

  return(
    list(
      message_echo = paste0('You\'ve sent: ', txt),
      number_echo = paste("The number is:", number),
      call = req$postBody,
      error = error
    )
  )

}

# run with: plumber::plumb("example01.R")$run(port = 5762)
# Go to the link provided
# Or use:
# curl "localhost:5762/echo?txt=Hi%20There" | jq "."
# curl --data '{"txt":"Hi there"}' "localhost:5762/echo" | jq '.'
# curl --data '{"txt":"Hi there", "number":553}' "localhost:5762/echo" | jq '.'
# Get the error
# curl --data '{"txt":"Hi there", "number":"foo"}' "localhost:5762/echo" | jq '.'
