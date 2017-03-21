Yet Another Dockerized Kafka
============================

An "as simple as possible" Kafka container that probably doesn't need
to exist but does none the less.

Main features:

* Has the [log compaction][log-compact] cleaner enabled (using the
  default settings)
* Has topic creation enabled
* Has topic deletion enabled
* Logs everything to `stdout` and `stderr`
* Exposes a volume for data storage
* Exposes JMX for monitoring/statistics gathering

[log-compact]: http://kafka.apache.org/documentation.html#compaction

## Build

    docker build -t ah45/kafka .

## Run

### Pre-requisites

An available ZooKeeper quorum. See [my ZooKeeper repo][zk] for a
container that might help you set one up (other containers/deployments
are available.)

[zk]: https://github.com/ah45/docker-zookeeper

### Example

    docker run \
      -d \
      --name kafka1 \
      --env ID=1 \
      --env ZOOKEEPER=zookeeper:2181 \
      --env EXT_HOST=192.168.1.10 \
      --env JMX_PORT=10000 \
      -p 9092:9092 \
      -p 10000:10000 \
      -v /tmp/kafka:/data \
      ah45/kafka

### `ENV` Variables

Required:

* `ID` the broker ID to run as.
* `ZOOKEEPER` the ZooKeeper connection string to use.

Strongly recommended:

* `EXT_HOST` the hostname/address to advertise as. This should be the
  _external_ address clients will be connecting to. Defaults to the
  container IP.

  This is used to set the Kafka `advertised.listeners` will be set to
  (to `PLAINTEXT://${EXT_HOST}:9092`) and the JMX address. Both settings
  will be overridden by more specific variables if given
  (`KAFKA_ADVERTISED_LISTENERS` and `JMX_HOST`, respectively.)

Optional:

* `JMX_HOST` the hostname/address to expose JMX on.
* `JMX_PORT` the port to expose for JMX connections, see the JMX
  section below for more details. Defaults to `7000`.

## Kafka Configuration

Any `KAFKA_*` environment variables will be used to set/override
`server.properties` settings, just replace the `.`s in the property name
with `_`s (e.g. `KAFKA_AUTO_CREATE_TOPICS_ENABLE=false` will result in
`auto.create.topics.enable=false` being written to the
`server.properties`.)

## Ports

Kafka will be running on port `9092` internally. JMX runs on whatever
port number you set `JMX_PORT` to, defaulting to port `7000`.

## Data Storage

All Kafka data is written to `/data` which is created as a Docker
volume. You'll probably want to mount it somewhere permanent and safe.

Application log files are stored within the container under
`/var/log/kafka` should you wish to re-mount or otherwise access
them.

## JMX

[Monitoring and statistics gathering of Kafka][monitor] is best done
via JMX. Unfortunately remote JMX access to processes running inside
Docker containers can be a little finicky to setup.

[monitor]: http://kafka.apache.org/documentation.html#monitoring

This image hopefully takes away most of the pain and confusion.

There are really only two things to remember:

* The external port needs to match the internal port.

  Don't map the internal port to an unknown external port (`-p <jmx
  port>`) or to a different external port (`-p <some port>:<jmx
  port>`) _always_ keep them the same (`-p <jmx port>:<jmx port>`.)
* JMX needs to know the _external_ IP clients will connect to.

  By default the `EXT_HOST` value is also used as the JMX hostname, if
  for some reason you need to specify a different value then do so as
  a `JMX_HOST` env variable (`--env JMX_HOST=<jmx host IP>`.)

So, you should have something like:

    --env EXT_HOST=192.168.99.100 --env JMX_PORT=7000 -p 7000:7000

… in your Docker `run` command and not anything like:

    -p 7000
    -p 32790:7000
    --env JMX_PORT=10000 -p 10000
    --env EXT_HOST=127.0.0.1 --env JMX_PORT=8080 -p 8080

Providing you adhere to those two maxims everything should just work.

### Security

Due to a desire not to overly complicate the configuration JMX is
running _un_secured: with no authentication and with SSL
disabled. Don't expose it to the outside world.

The "best" approach is would be to _not_ expose JMX on the Docker host
and instead run a metrics collector in another container linked to
this one. If you were to do that you don't need to set the `JMX_PORT`
(the default of 7000 should be fine) and should set `JMX_HOST` to the
link name you'll use (e.g. `--env JMX_HOST=kafka1` if you'll link it
to the collector container as `--link <kafka container>:kafka1`.)

## Logging

All of the Kafka logs are redirected to `stdout` and `stderr` rather
than being logged to files. `WARN`ings and `ERROR`s are logged to
`stderr` with everything else sent to `stdout`.

The JVM garbage collection logs are still produced, per default Kafka
configuration, and saved in `/var/log/kafkaServer-gc.log` but are
rotated on a ten file/50MB per file basis.

## References

[wurstmeister/kafka-docker](https://github.com/wurstmeister/kafka-docker)
for the primary inspiration and especially the use of `ENV` variables to
override `server.properties`.

[digital-wonderland/docker-kafka](https://github.com/digital-wonderland/docker-kafka)
another very agreeable Kafka image.

## License

Copyright © 2017 Adam Harper.

This project is licensed under the terms of the MIT license.
