# just a list of columns that we want stripped out before saving a derived dataset.  Very manual for now.
column_exclusion_helper_derived <- function(
  dat
) {
  # columns to be excluded.  Will also exclude some based on patterns
  excl_col <- c(
    'cpt_seq_date',
    'ca_qacurator',
    'ca_qa',
    'ca_qaissues',
    'ca_qaresolve',
    'curation_dt',
    # these follow a pattern but 'partial' seems like too common of a word so it scares me to do bulk exclusions.
    'qa_partial',
    'ca_partial',
    'pt_partial',
    'cdrug_partial',
    'rt_partial',
    'path_partial',
    'image_partial',
    'md_partial',
    'cpt_partial'
  )

  dat %<>%
    select(
      -any_of(excl_col),
      -matches('^vstat_'),
      -matches('start_time$'),
      -matches('stop_time$'),
      -matches('qamajor'),
      -matches('qaminor'),
      -matches('qaother'),
      -matches('qatype'),
      -matches('^qa_'),
      -matches('_complete$'),
      -matches('^completion_'),
      -matches('_qacurator$'),
      -matches('_qa$'),
      -matches('_qaissues$'),
      -matches('_qaresolve$'),
    )

  return(dat)
}
