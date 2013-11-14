-record(post, {id = 0,
               parent_id = 0}).

-record(ancestor_post, {id = 0,
                        ancestor_id = 0}).

-record(post_stats, {id = 0,
                     max = 0,
                     size = 1}).

-record(counter, {key,
                  value = 0}).

% (if count < page_size && min_post > max_post)