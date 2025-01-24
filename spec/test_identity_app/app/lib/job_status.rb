# This module provides a way share updates of job progress across the app

module JobStatus
  def self.report(name, progress: nil, message: nil, finished: nil)
    $redis.with do |r|
      key = "job_status:#{name.parameterize}"

      if (job_status_json = r.get(key))
        job_status = JSON.parse(job_status_json)
      else
        r.lpush "job_statuses", key
        job_status = { 'name' => name, 'started_at' => Time.now, 'message' => message || 'Initiating...' }
      end

      job_status['progress'] = progress if progress
      job_status['message'] = message if message
      job_status['updated_at'] = Time.now
      if finished
        job_status['finished_at'] = Time.now
        job_status['progress'] = 100
        job_status['message'] = 'Finished!'
      end

      r.set key, job_status.to_json

      if finished
        r.expire key, 300
      end
    end
  end

  def self.get_all
    job_statuses = []

    $redis.with do |r|
      dead_status_keys = []
      i = 0
      loop do
        key = r.lrange('job_statuses', i, i + 1).first
        break unless key

        if (job_status_json = r.get(key))
          data = JSON.parse(job_status_json)
          status = Status.new(**data.symbolize_keys)
          job_statuses.push(status)
        else
          dead_status_keys.push(key)
        end
        i += 1
      end

      dead_status_keys.each do |key|
        r.lrem 'job_statuses', 1, key
      end
    end

    job_statuses
  end

  def self.clean_old_statuses
    self.get_all.each do |js|
      if js.updated_at < 24.hours.ago
        self.report(js.name, finished: true)
      end
    end
  end

  class Status
    def initialize(name:, progress: 0, started_at:, finished_at: nil, updated_at:, message: nil)
      @name = name
      @progress = progress
      @started_at = Time.parse(started_at)
      @updated_at = Time.parse(updated_at)
      @finished_at = finished_at ? Time.parse(finished_at) : nil
      @message = message
    end

    def message
      @message
    end

    def name
      @name
    end

    def updated_at
      @updated_at
    end

    def started_at
      @started_at
    end

    def running_time
      if @finished_at
        @finished_at - @started_at
      else
        Time.now - @started_at
      end
    end

    def progress
      @progress || 0
    end

    def finished?
      @finished_at.present?
    end
  end
end
