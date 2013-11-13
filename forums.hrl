-record(post, {id = 0,
               parent_id = 0}).

-record(ancestor_post, {id = 0,
                        ancestor_id = 0}).

-record(counter, {key,
                  value = 0}).