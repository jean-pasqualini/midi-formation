vcl 4.0;

sub vcl_recv {
    // Remove all cookies except the session ID.
    if (req.http.Cookie) {
        set req.http.Cookie = ";" + req.http.Cookie;
        set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
        set req.http.Cookie = regsuball(req.http.Cookie, ";(PHPSESSID)=", "; \1=");
        set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");

        if (req.http.Cookie == "") {
            // If there are no more cookies, remove the header to get page cached.
            unset req.http.Cookie;
        }
    }
}

sub vcl_backend_response {
    /* By default, Varnish3 ignores Cache-Control: no-cache and private
       https://www.varnish-cache.org/docs/3.0/tutorial/increasing_your_hitrate.html#cache-control
     */
    if (beresp.http.Cache-Control ~ "private" ||
        beresp.http.Cache-Control ~ "no-cache" ||
        beresp.http.Cache-Control ~ "no-store"
    ) {
        set beresp.uncacheable = true;
    }
    
    return (deliver);
}

backend default {
              .host = "app";
              .port = "8080";
      }
