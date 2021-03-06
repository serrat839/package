#' Make Sentence
#'
#' This function allows you to create a sentence from a body of words loaded by this package
#' @param corpus List. A list output from tweet_gettr.
#' @param prompt String. A string containing a word to start the markov chain.
#' @param n Integer. The length of the sequence of words we want to match when generating a sentence.
#' @keywords sentence
#' @export
#' @examples
#' make_sentence(trump_tweets, prompt = "I")

make_sentence <- function(corpus, prompt = "", n = 1) {
  handles <- corpus$handles
  corpus <- corpus$tokens

  # No prompt available
  if (nchar(prompt) == 0) {
    selected_word <- sample(corpus[corpus$firsts, "raw_tokens"], 1)
  }

  # User prompted the sentence maker
  else {
    # determine if the prompt is IN our corpus
    regex_prompt <- paste0('^', prompt, '$')
    prompt_is_valid <- grepl(regex_prompt, corpus$lowercase_tokens, ignore.case = T)
    if (grepl("@", prompt)) {
      # do nothing lmfao
    }else if (!any(prompt_is_valid)) {
      return("This prompt is bad!")
    }
    selected_word <- prompt
  }

  sentence <- selected_word

  # if our first word contains an @, change our first word to an @, this allows us to search through our raw tokens.
  # Our selected word is already recorded in sentence, so we don't need to worry.
  if (grepl("@", selected_word)) {
    selected_word <- "@"
  }

  word_history <- list(stringr::str_to_lower(selected_word))
  while(!grepl('[.!?]|ENDOFLINE', sentence)) {
    matched_sequence <- find_sequence(word_history, corpus$lowercase_tokens)
    after_match <- corpus[matched_sequence, ]
    after_sentiment <- after_match$raw_tokens

    selected_word <- sample(after_sentiment, 1)
    if (grepl("@", selected_word)) {
      # @ is selected, our selected word is now an @ from our @ bank
      selected_at <- sample(handles,1, replace = T)
      sentence <- paste(sentence, selected_at)
      selected_word <- "@"
    } else if (grepl("[\\.|\\?|\\,|\\!]", selected_word)){
      # our selected word is punctuation, add it without spaces
      sentence <- paste0(sentence, selected_word)
    }  else {
      # our selected word is a word, add it with spaces
      sentence <- paste(sentence, selected_word)
    }

    word_history <- append(word_history, stringr::str_to_lower(selected_word))

    if (length(word_history) > n) {
      word_history[[1]] <- NULL
    }


  }

  sentence <- stringr::str_replace(sentence, " ENDOFLINE", "")
  return(sentence)
}
