class ReportsController < ApplicationController

  # NOTE: For additional performance and closer-to-realtime results, one could fetch
  #       today's data with a lower and/or no expiration and cache the last 4 days of data
  #       using today as a cache key and aggregate them. For the sake of this exercise, I'm
  #       opting not to add that complexity. The same applies to the below top_referers as well
  def top_urls
    cached_data = cache 'top_url_report', expires_in: 5.minutes do
      data = {}
      Visit.fetch_rows(
        "SELECT
            DATE_TRUNC('day', created_at)::DATE AS date,
            url,
            COUNT(id) AS visits
          FROM visits
          WHERE DATE_TRUNC('day', created_at)::DATE > (NOW() - INTERVAL '5 days')::DATE
          GROUP BY
            DATE_TRUNC('day', created_at)::DATE,
            url
          ORDER BY
            date ASC, COUNT(id) DESC"
      ) { |row|
        data[row[:date]] ||= []
        data[row[:date]] << {
          'url': row[:url],
          'visits': row[:visits]
        }
      }

      data
    end

    render json: cached_data
  end

  # NOTE: This may or may not use a seqscan depending on postgresql configuration and statistics state,
  #       which adds 30% overhead
  # NOTE: A future enhancement could be to use the cached top_urls data to create a series of OR statements
  #       as an optimization fence. In combination with caching the previous 4 days and using only live queries
  #       for recent data, this would speed this up a bit but at much additional complexity. KISS.
  def top_referers
    cached_data = cache 'top_referer_report', expires_in: 5.minutes do
      data = {}
      Visit.fetch_rows(
      "WITH raw_data AS (
          SELECT
            DATE_TRUNC('day', created_at)::DATE AS date,
            url,
            COUNT(id) AS visits
          FROM visits
          WHERE DATE_TRUNC('day', created_at)::DATE > (NOW() - INTERVAL '5 days')::DATE
          GROUP BY
            DATE_TRUNC('day', created_at)::DATE,
            url
        ), aggregated_urls AS (
          SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY date ORDER BY visits DESC) AS rank
          FROM raw_data
        )
        SELECT
          date,
          url,
          visits,
          (SELECT
            JSON_AGG(row)
            FROM (
              SELECT
                JSON_BUILD_OBJECT('url', COALESCE(referer, '(direct)'), 'visits', count(*)) AS row
              FROM
                visits
              WHERE
                DATE_TRUNC('day', created_at)::DATE = aggregated_urls.date AND
                url=aggregated_urls.url
              GROUP BY
                referer
              ORDER BY
                COUNT(*) DESC
              LIMIT 5)
            t) AS referers
        FROM
          aggregated_urls
        WHERE rank <= 10"
      ) { |row|
        data[row[:date]] ||= []
        data[row[:date]] << {
          'url': row[:url],
          'visits': row[:visits],
          'referers': JSON.parse(row[:referers])
        }
      }

      data
    end

    render json: cached_data
  end
end
