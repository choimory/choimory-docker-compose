# 목차

- [개요](#개요)
  - [현재 로컬 docker 상황](#현재-로컬-docker-상황)
- [plan1 확인](#plan1-확인)
  - [답변](#답변)
  - [먼저 짚을 점: plan1에 비밀번호가 평문으로 들어 있음](#먼저-짚을-점-plan1에-비밀번호가-평문으로-들어-있음)
  - [현재 상태](#현재-상태)
  - [진행 계획 (안)](#진행-계획-안)
  - [결정이 필요한 것](#결정이-필요한-것)
- [개별 compose 작성](#개별-compose-작성)
  - [답변](#답변-1)
  - [구조 (안)](#구조-안)
  - [한 파일 + profiles 방식은?](#한-파일--profiles-방식은)
  - [남은 결정](#남은-결정)
- [추가1](#추가1)
- [추가1 섹션 확인](#추가1-섹션-확인)
  - [답변](#답변-2)
  - [결정 사항 반영](#결정-사항-반영)
    - [버전 정리](#버전-정리)
  - [ES 메모리](#es-메모리)
  - [비밀번호 처리](#비밀번호-처리)
  - [확인할 점](#확인할-점)
- [비밀번호 마스킹, ES 8.19.23, 보안 모드](#비밀번호-마스킹-es-81923-보안-모드)
  - [답변](#답변-3)
  - [ES 보안 모드 설정](#es-보안-모드-설정)
  - [8.19.23 업그레이드 주의점](#81923-업그레이드-주의점)

---

# 개요

- 로컬에서 개발할때 사용할 docker compose 구성이 필요함
- 주로 db들임
- db 마운트 경로는 ~/choimory_workspace/DataGripProjects/docker_volume/{db_name:elasticsearch,postgres,redis,mysql..}
- 상시 켜있어야 하고 restart_always 등의 옵션도 있어야함

## 현재 로컬 docker 상황

```shell
╰─$ docker ps
CONTAINER ID   IMAGE                  COMMAND                   CREATED         STATUS      PORTS                                                                                      NAMES
c73d568bb31b   redis                  "docker-entrypoint.s…"   15 months ago   Up 3 days   0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp                                                redis_choimory
b8a74cb91370   elasticsearch:8.12.2   "/bin/tini -- /usr/l…"   15 months ago   Up 3 days   0.0.0.0:9200->9200/tcp, [::]:9200->9200/tcp, 0.0.0.0:9300->9300/tcp, [::]:9300->9300/tcp   elasticsearch_choimory
96d46e366337   postgres:16            "docker-entrypoint.s…"   15 months ago   Up 3 days   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp                                                postgres_choimory
```

```shell
╰─$ docker inspect postgres_choimory
[
    {
        "Id": "96d46e366337305a9bcf6867681fd2c65af14412e10dee3cb5f285b16a9f1027",
        "Created": "2025-07-13T03:25:48.202705666Z",
        "Path": "docker-entrypoint.sh",
        "Args": [
            "postgres"
        ],
        "State": {
            "Status": "running",
            "Running": true,
            "Paused": false,
            "Restarting": false,
            "OOMKilled": false,
            "Dead": false,
            "Pid": 611,
            "ExitCode": 0,
            "Error": "",
            "StartedAt": "2026-10-27T03:52:25.265148792Z",
            "FinishedAt": "2026-10-27T03:52:23.853382292Z"
        },
        "Image": "sha256:918e8e72b35b5370901965ce3da5a355c3537cb5e10c38e82c2b6f174b758334",
        "ResolvConfPath": "/var/lib/docker/containers/96d46e366337305a9bcf6867681fd2c65af14412e10dee3cb5f285b16a9f1027/resolv.conf",
        "HostnamePath": "/var/lib/docker/containers/96d46e366337305a9bcf6867681fd2c65af14412e10dee3cb5f285b16a9f1027/hostname",
        "HostsPath": "/var/lib/docker/containers/96d46e366337305a9bcf6867681fd2c65af14412e10dee3cb5f285b16a9f1027/hosts",
        "LogPath": "/var/lib/docker/containers/96d46e366337305a9bcf6867681fd2c65af14412e10dee3cb5f285b16a9f1027/96d46e366337305a9bcf6867681fd2c65af14412e10dee3cb5f285b16a9f1027-json.log",
        "Name": "/postgres_choimory",
        "RestartCount": 0,
        "Driver": "overlayfs",
        "Platform": "linux",
        "MountLabel": "",
        "ProcessLabel": "",
        "AppArmorProfile": "",
        "ExecIDs": null,
        "HostConfig": {
            "Binds": [
                "/Users/choimory/DataGripProjects/DockerMount/postgres/data:/var/lib/postgresql/data"
            ],
            "ContainerIDFile": "",
            "LogConfig": {
                "Type": "json-file",
                "Config": {}
            },
            "NetworkMode": "bridge",
            "PortBindings": {
                "5432/tcp": [
                    {
                        "HostIp": "",
                        "HostPort": "5432"
                    }
                ]
            },
            "RestartPolicy": {
                "Name": "always",
                "MaximumRetryCount": 0
            },
            "AutoRemove": false,
            "VolumeDriver": "",
            "VolumesFrom": null,
            "ConsoleSize": [
                62,
                193
            ],
            "CapAdd": null,
            "CapDrop": null,
            "CgroupnsMode": "private",
            "Dns": [],
            "DnsOptions": [],
            "DnsSearch": [],
            "ExtraHosts": null,
            "GroupAdd": null,
            "IpcMode": "private",
            "Cgroup": "",
            "Links": null,
            "OomScoreAdj": 0,
            "PidMode": "",
            "Privileged": false,
            "PublishAllPorts": false,
            "ReadonlyRootfs": false,
            "SecurityOpt": null,
            "UTSMode": "",
            "UsernsMode": "",
            "ShmSize": 67108864,
            "Runtime": "runc",
            "Isolation": "",
            "CpuShares": 0,
            "Memory": 0,
            "NanoCpus": 0,
            "CgroupParent": "",
            "BlkioWeight": 0,
            "BlkioWeightDevice": [],
            "BlkioDeviceReadBps": [],
            "BlkioDeviceWriteBps": [],
            "BlkioDeviceReadIOps": [],
            "BlkioDeviceWriteIOps": [],
            "CpuPeriod": 0,
            "CpuQuota": 0,
            "CpuRealtimePeriod": 0,
            "CpuRealtimeRuntime": 0,
            "CpusetCpus": "",
            "CpusetMems": "",
            "Devices": [],
            "DeviceCgroupRules": null,
            "DeviceRequests": null,
            "MemoryReservation": 0,
            "MemorySwap": 0,
            "MemorySwappiness": null,
            "OomKillDisable": null,
            "PidsLimit": null,
            "Ulimits": [],
            "CpuCount": 0,
            "CpuPercent": 0,
            "IOMaximumIOps": 0,
            "IOMaximumBandwidth": 0,
            "MaskedPaths": [
                "/proc/asound",
                "/proc/acpi",
                "/proc/interrupts",
                "/proc/kcore",
                "/proc/keys",
                "/proc/latency_stats",
                "/proc/timer_list",
                "/proc/timer_stats",
                "/proc/sched_debug",
                "/proc/scsi",
                "/sys/firmware",
                "/sys/devices/virtual/powercap"
            ],
            "ReadonlyPaths": [
                "/proc/bus",
                "/proc/fs",
                "/proc/irq",
                "/proc/sys",
                "/proc/sysrq-trigger"
            ]
        },
        "GraphDriver": {
            "Data": null,
            "Name": "overlayfs"
        },
        "Mounts": [
            {
                "Type": "bind",
                "Source": "/Users/choimory/DataGripProjects/DockerMount/postgres/data",
                "Destination": "/var/lib/postgresql/data",
                "Mode": "",
                "RW": true,
                "Propagation": "rprivate"
            }
        ],
        "Config": {
            "Hostname": "96d46e366337",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "ExposedPorts": {
                "5432/tcp": {}
            },
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": [
                "POSTGRES_USER=choimory",
                "POSTGRES_PASSWORD=****",
                "POSTGRESQL_REPLICATION_USE_PASSFILE=NO",
                "TZ=Asia/Seoul",
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/postgresql/16/bin",
                "GOSU_VERSION=1.17",
                "LANG=en_US.utf8",
                "PG_MAJOR=16",
                "PG_VERSION=16.9-1.pgdg120+1",
                "PGDATA=/var/lib/postgresql/data"
            ],
            "Cmd": [
                "postgres"
            ],
            "Image": "postgres:16",
            "Volumes": {
                "/var/lib/postgresql/data": {}
            },
            "WorkingDir": "",
            "Entrypoint": [
                "docker-entrypoint.sh"
            ],
            "OnBuild": null,
            "Labels": {},
            "StopSignal": "SIGINT"
        },
        "NetworkSettings": {
            "Bridge": "",
            "SandboxID": "bb16c43d281c190049dda5e7bb6acc4fcea91b45ae31aad005156867a1018bea",
            "SandboxKey": "/var/run/docker/netns/bb16c43d281c",
            "Ports": {
                "5432/tcp": [
                    {
                        "HostIp": "0.0.0.0",
                        "HostPort": "5432"
                    },
                    {
                        "HostIp": "::",
                        "HostPort": "5432"
                    }
                ]
            },
            "HairpinMode": false,
            "LinkLocalIPv6Address": "",
            "LinkLocalIPv6PrefixLen": 0,
            "SecondaryIPAddresses": null,
            "SecondaryIPv6Addresses": null,
            "EndpointID": "a200c43abbe1ba5b5ed15bf5e53bdd9776a4396fcca37e0670f5e9ad99368926",
            "Gateway": "172.17.0.1",
            "GlobalIPv6Address": "",
            "GlobalIPv6PrefixLen": 0,
            "IPAddress": "172.17.0.4",
            "IPPrefixLen": 16,
            "IPv6Gateway": "",
            "MacAddress": "3e:67:5a:3b:ed:3e",
            "Networks": {
                "bridge": {
                    "IPAMConfig": null,
                    "Links": null,
                    "Aliases": null,
                    "MacAddress": "3e:67:5a:3b:ed:3e",
                    "DriverOpts": null,
                    "GwPriority": 0,
                    "NetworkID": "a0221ade4e06e2eb675b37056c0d34a319fbf822517d35c491033c756dd608e0",
                    "EndpointID": "a200c43abbe1ba5b5ed15bf5e53bdd9776a4396fcca37e0670f5e9ad99368926",
                    "Gateway": "172.17.0.1",
                    "IPAddress": "172.17.0.4",
                    "IPPrefixLen": 16,
                    "IPv6Gateway": "",
                    "GlobalIPv6Address": "",
                    "GlobalIPv6PrefixLen": 0,
                    "DNSNames": null
                }
            }
        },
        "ImageManifestDescriptor": {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:03ec65705b15684e3c1d52b1dd88f21db69a454864630dfb9eda4181bbb152af",
            "size": 3631,
            "annotations": {
                "com.docker.official-images.bashbrew.arch": "arm64v8",
                "org.opencontainers.image.base.digest": "sha256:4d7f63db765ea90bd6bbc4fab5be3df7d3f8030009f397ad6649d876763917d7",
                "org.opencontainers.image.base.name": "debian:bookworm-slim",
                "org.opencontainers.image.created": "2025-07-01T06:10:04Z",
                "org.opencontainers.image.revision": "2c6fe8daca9d2ccc143afe6b1cdbc1eb80379d3f",
                "org.opencontainers.image.source": "https://github.com/docker-library/postgres.git#2c6fe8daca9d2ccc143afe6b1cdbc1eb80379d3f:16/bookworm",
                "org.opencontainers.image.url": "https://hub.docker.com/_/postgres",
                "org.opencontainers.image.version": "16.9"
            },
            "platform": {
                "architecture": "arm64",
                "os": "linux",
                "variant": "v8"
            }
        }
    }
]
```

```shell
╰─$ docker inspect redis_choimory   
[
    {
        "Id": "c73d568bb31b748a00b49b3e3a048f59ffdd7a3a9c2a6c1f145dfded7981babe",
        "Created": "2025-07-13T12:51:24.324773884Z",
        "Path": "docker-entrypoint.sh",
        "Args": [
            "redis-server"
        ],
        "State": {
            "Status": "running",
            "Running": true,
            "Paused": false,
            "Restarting": false,
            "OOMKilled": false,
            "Dead": false,
            "Pid": 614,
            "ExitCode": 0,
            "Error": "",
            "StartedAt": "2026-10-27T03:52:25.262586751Z",
            "FinishedAt": "2026-10-27T03:52:23.853827458Z"
        },
        "Image": "sha256:a1e0a3b3a6cedd74d8ba44805b2497b93851a296f08a44962fedc03f1c490b47",
        "ResolvConfPath": "/var/lib/docker/containers/c73d568bb31b748a00b49b3e3a048f59ffdd7a3a9c2a6c1f145dfded7981babe/resolv.conf",
        "HostnamePath": "/var/lib/docker/containers/c73d568bb31b748a00b49b3e3a048f59ffdd7a3a9c2a6c1f145dfded7981babe/hostname",
        "HostsPath": "/var/lib/docker/containers/c73d568bb31b748a00b49b3e3a048f59ffdd7a3a9c2a6c1f145dfded7981babe/hosts",
        "LogPath": "/var/lib/docker/containers/c73d568bb31b748a00b49b3e3a048f59ffdd7a3a9c2a6c1f145dfded7981babe/c73d568bb31b748a00b49b3e3a048f59ffdd7a3a9c2a6c1f145dfded7981babe-json.log",
        "Name": "/redis_choimory",
        "RestartCount": 0,
        "Driver": "overlayfs",
        "Platform": "linux",
        "MountLabel": "",
        "ProcessLabel": "",
        "AppArmorProfile": "",
        "ExecIDs": null,
        "HostConfig": {
            "Binds": null,
            "ContainerIDFile": "",
            "LogConfig": {
                "Type": "json-file",
                "Config": {}
            },
            "NetworkMode": "bridge",
            "PortBindings": {
                "6379/tcp": [
                    {
                        "HostIp": "",
                        "HostPort": "6379"
                    }
                ]
            },
            "RestartPolicy": {
                "Name": "always",
                "MaximumRetryCount": 0
            },
            "AutoRemove": false,
            "VolumeDriver": "",
            "VolumesFrom": null,
            "ConsoleSize": [
                13,
                277
            ],
            "CapAdd": null,
            "CapDrop": null,
            "CgroupnsMode": "private",
            "Dns": [],
            "DnsOptions": [],
            "DnsSearch": [],
            "ExtraHosts": null,
            "GroupAdd": null,
            "IpcMode": "private",
            "Cgroup": "",
            "Links": null,
            "OomScoreAdj": 0,
            "PidMode": "",
            "Privileged": false,
            "PublishAllPorts": false,
            "ReadonlyRootfs": false,
            "SecurityOpt": null,
            "UTSMode": "",
            "UsernsMode": "",
            "ShmSize": 67108864,
            "Runtime": "runc",
            "Isolation": "",
            "CpuShares": 0,
            "Memory": 0,
            "NanoCpus": 0,
            "CgroupParent": "",
            "BlkioWeight": 0,
            "BlkioWeightDevice": [],
            "BlkioDeviceReadBps": [],
            "BlkioDeviceWriteBps": [],
            "BlkioDeviceReadIOps": [],
            "BlkioDeviceWriteIOps": [],
            "CpuPeriod": 0,
            "CpuQuota": 0,
            "CpuRealtimePeriod": 0,
            "CpuRealtimeRuntime": 0,
            "CpusetCpus": "",
            "CpusetMems": "",
            "Devices": [],
            "DeviceCgroupRules": null,
            "DeviceRequests": null,
            "MemoryReservation": 0,
            "MemorySwap": 0,
            "MemorySwappiness": null,
            "OomKillDisable": null,
            "PidsLimit": null,
            "Ulimits": [],
            "CpuCount": 0,
            "CpuPercent": 0,
            "IOMaximumIOps": 0,
            "IOMaximumBandwidth": 0,
            "MaskedPaths": [
                "/proc/asound",
                "/proc/acpi",
                "/proc/interrupts",
                "/proc/kcore",
                "/proc/keys",
                "/proc/latency_stats",
                "/proc/timer_list",
                "/proc/timer_stats",
                "/proc/sched_debug",
                "/proc/scsi",
                "/sys/firmware",
                "/sys/devices/virtual/powercap"
            ],
            "ReadonlyPaths": [
                "/proc/bus",
                "/proc/fs",
                "/proc/irq",
                "/proc/sys",
                "/proc/sysrq-trigger"
            ]
        },
        "GraphDriver": {
            "Data": null,
            "Name": "overlayfs"
        },
        "Mounts": [
            {
                "Type": "volume",
                "Name": "fc6dc0823c8910cf02be45830442d3c5ec76c03d7acafa5d1671fa45d0fa9bbc",
                "Source": "/var/lib/docker/volumes/fc6dc0823c8910cf02be45830442d3c5ec76c03d7acafa5d1671fa45d0fa9bbc/_data",
                "Destination": "/data",
                "Driver": "local",
                "Mode": "",
                "RW": true,
                "Propagation": ""
            }
        ],
        "Config": {
            "Hostname": "c73d568bb31b",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "ExposedPorts": {
                "6379/tcp": {}
            },
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
                "REDIS_DOWNLOAD_URL=https://github.com/redis/redis/archive/refs/tags/8.0.3.tar.gz",
                "REDIS_DOWNLOAD_SHA=2467b9608ecbcc2c0d27397c0c2406b499b6f68bc08ac9f6380b1faf2113ae6f"
            ],
            "Cmd": [
                "redis-server"
            ],
            "Image": "redis",
            "Volumes": {
                "/data": {}
            },
            "WorkingDir": "/data",
            "Entrypoint": [
                "docker-entrypoint.sh"
            ],
            "OnBuild": null,
            "Labels": {}
        },
        "NetworkSettings": {
            "Bridge": "",
            "SandboxID": "59506e22a572987c07f353426954dbb7084b9f2100f752d600ac77885a0d3201",
            "SandboxKey": "/var/run/docker/netns/59506e22a572",
            "Ports": {
                "6379/tcp": [
                    {
                        "HostIp": "0.0.0.0",
                        "HostPort": "6379"
                    },
                    {
                        "HostIp": "::",
                        "HostPort": "6379"
                    }
                ]
            },
            "HairpinMode": false,
            "LinkLocalIPv6Address": "",
            "LinkLocalIPv6PrefixLen": 0,
            "SecondaryIPAddresses": null,
            "SecondaryIPv6Addresses": null,
            "EndpointID": "13a5ca4496554e392d5b302013928aedcdae0bf64faa403f8d7634120b57fe48",
            "Gateway": "172.17.0.1",
            "GlobalIPv6Address": "",
            "GlobalIPv6PrefixLen": 0,
            "IPAddress": "172.17.0.3",
            "IPPrefixLen": 16,
            "IPv6Gateway": "",
            "MacAddress": "5e:b8:60:25:4a:30",
            "Networks": {
                "bridge": {
                    "IPAMConfig": null,
                    "Links": null,
                    "Aliases": null,
                    "MacAddress": "5e:b8:60:25:4a:30",
                    "DriverOpts": null,
                    "GwPriority": 0,
                    "NetworkID": "a0221ade4e06e2eb675b37056c0d34a319fbf822517d35c491033c756dd608e0",
                    "EndpointID": "13a5ca4496554e392d5b302013928aedcdae0bf64faa403f8d7634120b57fe48",
                    "Gateway": "172.17.0.1",
                    "IPAddress": "172.17.0.3",
                    "IPPrefixLen": 16,
                    "IPv6Gateway": "",
                    "GlobalIPv6Address": "",
                    "GlobalIPv6PrefixLen": 0,
                    "DNSNames": null
                }
            }
        },
        "ImageManifestDescriptor": {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:b0991c10a8f7a6565aab5784d1de61f32b4ab2ce6c7d23c286a523d96c879239",
            "size": 2290,
            "annotations": {
                "com.docker.official-images.bashbrew.arch": "arm64v8",
                "org.opencontainers.image.base.digest": "sha256:4d7f63db765ea90bd6bbc4fab5be3df7d3f8030009f397ad6649d876763917d7",
                "org.opencontainers.image.base.name": "debian:bookworm-slim",
                "org.opencontainers.image.created": "2025-07-07T16:45:21Z",
                "org.opencontainers.image.revision": "101262a8cf05b98137d88bc17e77db90c24cc783",
                "org.opencontainers.image.source": "https://github.com/redis/docker-library-redis.git#101262a8cf05b98137d88bc17e77db90c24cc783:debian",
                "org.opencontainers.image.url": "https://hub.docker.com/_/redis",
                "org.opencontainers.image.version": "8.0.3"
            },
            "platform": {
                "architecture": "arm64",
                "os": "linux",
                "variant": "v8"
            }
        }
    }
]
```

```shell
╰─$ docker inspect elasticsearch_choimory 
[
    {
        "Id": "b8a74cb9137074a962c9ae98db254ba400e86b332a90d6116a5d55eb94fa2de5",
        "Created": "2025-07-13T07:29:52.013088964Z",
        "Path": "/bin/tini",
        "Args": [
            "--",
            "/usr/local/bin/docker-entrypoint.sh",
            "eswrapper"
        ],
        "State": {
            "Status": "running",
            "Running": true,
            "Paused": false,
            "Restarting": false,
            "OOMKilled": false,
            "Dead": false,
            "Pid": 612,
            "ExitCode": 0,
            "Error": "",
            "StartedAt": "2026-10-27T03:52:25.266335459Z",
            "FinishedAt": "2026-10-27T03:52:23.853871375Z"
        },
        "Image": "sha256:1d183abc10a89d49a9a7c8c9aeebc32bbd9de91782b4b3d39a1318469f5ad8c3",
        "ResolvConfPath": "/var/lib/docker/containers/b8a74cb9137074a962c9ae98db254ba400e86b332a90d6116a5d55eb94fa2de5/resolv.conf",
        "HostnamePath": "/var/lib/docker/containers/b8a74cb9137074a962c9ae98db254ba400e86b332a90d6116a5d55eb94fa2de5/hostname",
        "HostsPath": "/var/lib/docker/containers/b8a74cb9137074a962c9ae98db254ba400e86b332a90d6116a5d55eb94fa2de5/hosts",
        "LogPath": "/var/lib/docker/containers/b8a74cb9137074a962c9ae98db254ba400e86b332a90d6116a5d55eb94fa2de5/b8a74cb9137074a962c9ae98db254ba400e86b332a90d6116a5d55eb94fa2de5-json.log",
        "Name": "/elasticsearch_choimory",
        "RestartCount": 0,
        "Driver": "overlayfs",
        "Platform": "linux",
        "MountLabel": "",
        "ProcessLabel": "",
        "AppArmorProfile": "",
        "ExecIDs": null,
        "HostConfig": {
            "Binds": [
                "/Users/choimory/DataGripProjects/DockerMount/elasticsearch/data:/usr/share/elasticsearch/data"
            ],
            "ContainerIDFile": "",
            "LogConfig": {
                "Type": "json-file",
                "Config": {}
            },
            "NetworkMode": "bridge",
            "PortBindings": {
                "9200/tcp": [
                    {
                        "HostIp": "",
                        "HostPort": "9200"
                    }
                ],
                "9300/tcp": [
                    {
                        "HostIp": "",
                        "HostPort": "9300"
                    }
                ]
            },
            "RestartPolicy": {
                "Name": "always",
                "MaximumRetryCount": 0
            },
            "AutoRemove": false,
            "VolumeDriver": "",
            "VolumesFrom": null,
            "ConsoleSize": [
                62,
                193
            ],
            "CapAdd": null,
            "CapDrop": null,
            "CgroupnsMode": "private",
            "Dns": [],
            "DnsOptions": [],
            "DnsSearch": [],
            "ExtraHosts": null,
            "GroupAdd": null,
            "IpcMode": "private",
            "Cgroup": "",
            "Links": null,
            "OomScoreAdj": 0,
            "PidMode": "",
            "Privileged": false,
            "PublishAllPorts": false,
            "ReadonlyRootfs": false,
            "SecurityOpt": null,
            "UTSMode": "",
            "UsernsMode": "",
            "ShmSize": 67108864,
            "Runtime": "runc",
            "Isolation": "",
            "CpuShares": 0,
            "Memory": 0,
            "NanoCpus": 0,
            "CgroupParent": "",
            "BlkioWeight": 0,
            "BlkioWeightDevice": [],
            "BlkioDeviceReadBps": [],
            "BlkioDeviceWriteBps": [],
            "BlkioDeviceReadIOps": [],
            "BlkioDeviceWriteIOps": [],
            "CpuPeriod": 0,
            "CpuQuota": 0,
            "CpuRealtimePeriod": 0,
            "CpuRealtimeRuntime": 0,
            "CpusetCpus": "",
            "CpusetMems": "",
            "Devices": [],
            "DeviceCgroupRules": null,
            "DeviceRequests": null,
            "MemoryReservation": 0,
            "MemorySwap": 0,
            "MemorySwappiness": null,
            "OomKillDisable": null,
            "PidsLimit": null,
            "Ulimits": [],
            "CpuCount": 0,
            "CpuPercent": 0,
            "IOMaximumIOps": 0,
            "IOMaximumBandwidth": 0,
            "MaskedPaths": [
                "/proc/asound",
                "/proc/acpi",
                "/proc/interrupts",
                "/proc/kcore",
                "/proc/keys",
                "/proc/latency_stats",
                "/proc/timer_list",
                "/proc/timer_stats",
                "/proc/sched_debug",
                "/proc/scsi",
                "/sys/firmware",
                "/sys/devices/virtual/powercap"
            ],
            "ReadonlyPaths": [
                "/proc/bus",
                "/proc/fs",
                "/proc/irq",
                "/proc/sys",
                "/proc/sysrq-trigger"
            ]
        },
        "GraphDriver": {
            "Data": null,
            "Name": "overlayfs"
        },
        "Mounts": [
            {
                "Type": "bind",
                "Source": "/Users/choimory/DataGripProjects/DockerMount/elasticsearch/data",
                "Destination": "/usr/share/elasticsearch/data",
                "Mode": "",
                "RW": true,
                "Propagation": "rprivate"
            }
        ],
        "Config": {
            "Hostname": "b8a74cb91370",
            "Domainname": "",
            "User": "1000:0",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "ExposedPorts": {
                "9200/tcp": {},
                "9300/tcp": {}
            },
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": [
                "discovery.type=single-node",
                "ELASTIC_PASSWORD=****",
                "xpack.security.enabled=false",
                "PATH=/usr/share/elasticsearch/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
                "ELASTIC_CONTAINER=true"
            ],
            "Cmd": [
                "eswrapper"
            ],
            "Image": "elasticsearch:8.12.2",
            "Volumes": null,
            "WorkingDir": "/usr/share/elasticsearch",
            "Entrypoint": [
                "/bin/tini",
                "--",
                "/usr/local/bin/docker-entrypoint.sh"
            ],
            "OnBuild": null,
            "Labels": {
                "org.label-schema.build-date": "2024-02-19T10:04:32.774273190Z",
                "org.label-schema.license": "Elastic-License-2.0",
                "org.label-schema.name": "Elasticsearch",
                "org.label-schema.schema-version": "1.0",
                "org.label-schema.url": "https://www.elastic.co/products/elasticsearch",
                "org.label-schema.usage": "https://www.elastic.co/guide/en/elasticsearch/reference/index.html",
                "org.label-schema.vcs-ref": "48a287ab9497e852de30327444b0809e55d46466",
                "org.label-schema.vcs-url": "https://github.com/elastic/elasticsearch",
                "org.label-schema.vendor": "Elastic",
                "org.label-schema.version": "8.12.2",
                "org.opencontainers.image.created": "2024-02-19T10:04:32.774273190Z",
                "org.opencontainers.image.documentation": "https://www.elastic.co/guide/en/elasticsearch/reference/index.html",
                "org.opencontainers.image.licenses": "Elastic-License-2.0",
                "org.opencontainers.image.ref.name": "ubuntu",
                "org.opencontainers.image.revision": "48a287ab9497e852de30327444b0809e55d46466",
                "org.opencontainers.image.source": "https://github.com/elastic/elasticsearch",
                "org.opencontainers.image.title": "Elasticsearch",
                "org.opencontainers.image.url": "https://www.elastic.co/products/elasticsearch",
                "org.opencontainers.image.vendor": "Elastic",
                "org.opencontainers.image.version": "8.12.2"
            }
        },
        "NetworkSettings": {
            "Bridge": "",
            "SandboxID": "d6bdf4fbcf36c9821474ad0bdcd48334dfd04ac77748138bb8566040c549abf9",
            "SandboxKey": "/var/run/docker/netns/d6bdf4fbcf36",
            "Ports": {
                "9200/tcp": [
                    {
                        "HostIp": "0.0.0.0",
                        "HostPort": "9200"
                    },
                    {
                        "HostIp": "::",
                        "HostPort": "9200"
                    }
                ],
                "9300/tcp": [
                    {
                        "HostIp": "0.0.0.0",
                        "HostPort": "9300"
                    },
                    {
                        "HostIp": "::",
                        "HostPort": "9300"
                    }
                ]
            },
            "HairpinMode": false,
            "LinkLocalIPv6Address": "",
            "LinkLocalIPv6PrefixLen": 0,
            "SecondaryIPAddresses": null,
            "SecondaryIPv6Addresses": null,
            "EndpointID": "2698c07e0f85b75d4158ffd1fe3e2a221dd898204efb6fa5d1b5901094814167",
            "Gateway": "172.17.0.1",
            "GlobalIPv6Address": "",
            "GlobalIPv6PrefixLen": 0,
            "IPAddress": "172.17.0.2",
            "IPPrefixLen": 16,
            "IPv6Gateway": "",
            "MacAddress": "be:fe:54:35:a2:74",
            "Networks": {
                "bridge": {
                    "IPAMConfig": null,
                    "Links": null,
                    "Aliases": null,
                    "MacAddress": "be:fe:54:35:a2:74",
                    "DriverOpts": null,
                    "GwPriority": 0,
                    "NetworkID": "a0221ade4e06e2eb675b37056c0d34a319fbf822517d35c491033c756dd608e0",
                    "EndpointID": "2698c07e0f85b75d4158ffd1fe3e2a221dd898204efb6fa5d1b5901094814167",
                    "Gateway": "172.17.0.1",
                    "IPAddress": "172.17.0.2",
                    "IPPrefixLen": 16,
                    "IPv6Gateway": "",
                    "GlobalIPv6Address": "",
                    "GlobalIPv6PrefixLen": 0,
                    "DNSNames": null
                }
            }
        },
        "ImageManifestDescriptor": {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:359d968038cb6143dbc10bf6b32e9f335b8d5e6c267fb56a399c3cf1fe0d914b",
            "size": 2868,
            "annotations": {
                "com.docker.official-images.bashbrew.arch": "arm64v8",
                "org.opencontainers.image.base.digest": "sha256:4aa61d4985265be6d872cc214016f2f91a77b1c925dab5ce502db2edc4a7e5af",
                "org.opencontainers.image.base.name": "ubuntu:20.04",
                "org.opencontainers.image.created": "2024-03-06T16:16:47Z",
                "org.opencontainers.image.revision": "e2fb0b9e1ab9298119afe3cad839cac90a620a82",
                "org.opencontainers.image.source": "https://github.com/elastic/dockerfiles.git#e2fb0b9e1ab9298119afe3cad839cac90a620a82:elasticsearch",
                "org.opencontainers.image.url": "https://hub.docker.com/_/elasticsearch",
                "org.opencontainers.image.version": "8.12.2"
            },
            "platform": {
                "architecture": "arm64",
                "os": "linux",
                "variant": "v8"
            }
        }
    }
]
```

---

# plan1 확인

> plan1 확인

## 답변

현재 맥북(arm64)에서 컨테이너 3개가 `docker run`으로 15개월째 돌고 있고, 이것을 compose로 옮기는 작업이 됨

## 먼저 짚을 점: plan1에 비밀번호가 평문으로 들어 있음

`docker inspect` 결과에 비밀번호 두 개가 그대로 들어 있음

- `POSTGRES_PASSWORD`
- `ELASTIC_PASSWORD`

문서 규칙상 민감한 정보는 마스킹해야 하고, 저장소를 public으로 공개할 계획이기도 함. 커밋 전에 `****`로 마스킹 필요

## 현재 상태

| 컨테이너 | 이미지 | 포트 | 데이터 저장 | 재시작 |
| --- | --- | --- | --- | --- |
| postgres_choimory | `postgres:16` (16.9) | 0.0.0.0:5432 | bind `~/DataGripProjects/DockerMount/postgres/data` | always |
| redis_choimory | `redis` (태그 없음, 8.0.3) | 0.0.0.0:6379 | **익명 볼륨** | always |
| elasticsearch_choimory | `elasticsearch:8.12.2` | 0.0.0.0:9200, 9300 | bind `~/DataGripProjects/DockerMount/elasticsearch/data` | always |

- **데이터 경로가 바뀜**: 현재는 `~/DataGripProjects/DockerMount/...`이고, 원하는 경로는 `~/choimory_workspace/DataGripProjects/docker_volume/...`. 기존 데이터를 옮겨야 함
- **Redis 데이터가 익명 볼륨에 있음**: 컨테이너를 지우면 데이터도 같이 사라질 수 있음
- **포트가 0.0.0.0에 열려 있음**: 스터디카페 와이파이 같은 곳에서는 같은 네트워크의 다른 사람이 DB 포트에 접근할 수 있음
- **Elasticsearch 설정**
  - 메모리 제한이 없어 JVM이 메모리를 크게 잡을 수 있음
  - `xpack.security.enabled=false`라서 `ELASTIC_PASSWORD`는 실제로 쓰이지 않음

## 진행 계획 (안)

1. **compose 구조**: 로컬은 DB를 함께 띄우는 경우가 많고 Dockge도 없음. 그래서 서버와 달리 **compose 파일 하나**에 DB를 모두 넣는 걸 추천
2. **데이터 경로**: `.env`의 `${HOME}`을 기준으로 `docker_volume/{postgres,redis,elasticsearch}`에 bind mount. compose는 `~`를 펼치지 못하므로 `${HOME}`을 씀
3. **이미지 버전**: 우선 현재와 같은 버전으로 고정해 데이터를 그대로 옮김
   - Postgres: 16. 메이저 버전을 올리려면 dump 후 restore가 필요함
   - Redis: 8.0.3
   - Elasticsearch: 8.12.2
   - 버전 업그레이드는 이전이 끝난 뒤 따로 진행
4. **설정**
   - 재시작: 요청대로 `restart: always`
   - 포트: `127.0.0.1`에만 바인딩
   - 공통: `TZ=Asia/Seoul`
   - Elasticsearch: `ES_JAVA_OPTS=-Xms1g -Xmx1g`
   - 비밀번호: `.env`로 분리
5. **이전 순서**
   1. 기존 컨테이너 중지
   2. 데이터 디렉토리를 새 경로로 옮김
   3. Redis 데이터는 `docker cp`로 꺼냄
   4. 기존 컨테이너 삭제. `container_name`이 같으면 충돌하기 때문
   5. `docker compose up -d`로 기동

## 결정이 필요한 것

1. **저장소 위치**: 비어 있는 `choimory-dev/`를 쓸지, `choimory-local/`을 새로 만들지
2. **MySQL**: 경로 예시에 mysql이 있는데, 지금은 돌고 있지 않음. 새로 추가할지, 추가한다면 버전은 무엇으로 할지
3. **Redis 데이터**: 옮길지, 캐시 용도라 버려도 되는지
4. **포트**: `127.0.0.1` 바인딩으로 괜찮은지. 다른 기기에서 맥북 DB에 접속할 일이 있는지
5. **Docker 런타임**: Docker Desktop인지 OrbStack인지. bind mount 성능과 경로 동작이 조금 다름
6. **Elasticsearch 메모리**: 1GB로 충분한지

---

# 개별 compose 작성

> 이건 내가 띄우고 싶은 것만 골라 띄울수 있게 개별로 compose 작성해야할듯

## 답변

동의. 서버처럼 서비스마다 디렉토리 하나씩 두는 구조로 감

## 구조 (안)

```txt
choimory-local/            # 또는 choimory-dev/ (결정 필요)
├── postgres/        compose.yaml, .env.example
├── redis/           compose.yaml
├── elasticsearch/   compose.yaml, .env.example
└── mysql/           compose.yaml, .env.example   # 추가할 경우
```

- **원하는 것만 띄우기**: 해당 디렉토리에서 `docker compose up -d` 실행. 한 번 띄우면 `restart: always`라서 Docker를 재시작해도 다시 뜸. 끄고 싶을 때는 `docker compose down`
- **네트워크는 공유하지 않음**: 로컬 앱이나 DataGrip은 `localhost:포트`로 접속하므로 compose 사이를 연결할 필요가 없음. Kibana처럼 특정 DB에 붙는 도구는 같은 디렉토리 compose에 함께 넣음
- **데이터 경로는 compose에 직접 씀**: 예: `${HOME}/choimory_workspace/DataGripProjects/docker_volume/postgres`. `.env`는 비밀번호가 있는 서비스에만 둠
- **프로젝트명**: `name: local-postgres`처럼 `local-` 접두사를 붙임. 다른 프로젝트의 compose와 이름이 겹치지 않게 하기 위함
- **`container_name`**: 기존 이름(`postgres_choimory` 등)을 그대로 씀. 익숙한 이름을 유지하려는 것이고, 기존 컨테이너를 지운 뒤에 띄우면 충돌하지 않음

## 한 파일 + profiles 방식은?

compose 파일 하나에 `profiles`를 붙여 `docker compose --profile postgres up -d`처럼 골라 띄우는 방법도 있음. 다만 아래 이유로 개별 디렉토리 방식을 추천

- 서버 쪽(`choimory-server/`)과 구조가 같아서 헷갈리지 않음
- 서비스 하나를 내리거나 버전을 올릴 때 다른 서비스에 영향이 없음
- 명령어가 단순함

## 남은 결정

1. **저장소 위치**: `choimory-dev/`를 쓸지, `choimory-local/`을 새로 만들지
2. **MySQL**: 추가할지, 추가한다면 버전은 무엇으로 할지
3. **Redis 데이터**: 옮길지, 버려도 되는지
4. **포트**: `127.0.0.1` 바인딩으로 괜찮은지
5. **Docker 런타임**: Docker Desktop인지 OrbStack인지
6. **Elasticsearch 메모리**: 1GB로 충분한지

---

# 추가1

- choimory-local 추가해뒀음
- MySQL 8 중에 LTS (가장 대표적인 버전)
- Redis 데이터 버려도 됨
- 로컬호스트:DB별 기본포트
- docker desktop임 
- ES 메모리: 얼마나 좋을까?
- 그 외
  - 도커 마운트 위치는 변경할 계획이므로 내가 지금 말해준 위치가 맞음
  - password 같은 적기 곤란한 민감한 내용은 그냥 주석쳐놓으면 내가 사용할때 변경해서 사용함

---

# 추가1 섹션 확인

> 추가1 섹션 확인

## 답변

대부분 그대로 반영하면 되고, 보완할 것은 MySQL 버전, ES 메모리, 비밀번호 처리 방식 세 가지

## 결정 사항 반영

| 항목 | 결정 | 반영 내용 |
| --- | --- | --- |
| 저장소 위치 | `choimory-local/` | 이미 만들어 둔 디렉토리 사용 (`choimory-dev/`는 choimory-dev 프로젝트용) |
| MySQL | 8 LTS | `mysql:8.4.13` |
| Redis 데이터 | 버림 | 이전 작업 없이 새로 시작하므로 최신 `redis:8.10.3` 사용 |
| 포트 | localhost:기본포트 | `127.0.0.1:5432`, `6379`, `9200`, `3306` |
| 런타임 | Docker Desktop | `/Users` 아래 bind mount는 기본으로 공유되어 추가 설정 없음 |
| 마운트 위치 | `~/choimory_workspace/DataGripProjects/docker_volume/{db}` | compose에서 `${HOME}/choimory_workspace/...`로 지정 |

### 버전 정리

- **MySQL**: 가장 많이 쓰인 버전은 8.0이지만 2026년 4월에 지원이 끝남. 현재 8 계열의 LTS는 **8.4**
  - 8.4는 기본 인증이 `caching_sha2_password`이고, `mysql_native_password`는 기본으로 꺼져 있음
  - DataGrip이나 최신 드라이버는 문제없음
- **Postgres**: `16.9` → `16.15`. 같은 메이저 버전 안의 패치 업그레이드라 데이터를 그대로 쓸 수 있음
- **Elasticsearch**: 데이터를 옮기므로 우선 `8.12.2` 유지. 같은 8.x 안에서는 `8.19.23`으로 바로 올려도 데이터가 호환됨
- **ES 9300 포트**: 노드 간 통신용이라 단일 노드 로컬 환경에서는 필요 없어서 뺌
- **`ELASTIC_PASSWORD`**: 보안 기능이 꺼져 있어 쓰이지 않으므로 뺌

## ES 메모리

**`1g`를 추천**하고, `.env`로 바꿀 수 있게 둠

- **값을 지정해야 하는 이유**: 지정하지 않으면 ES 8이 컨테이너 메모리의 절반을 힙으로 잡음. Docker Desktop에서는 VM 전체 메모리 기준이라 생각보다 크게 잡힘. 지금 컨테이너의 메모리 제한이 0(무제한)인 것도 이 상태
- **로컬 개발용 기준**
  - 인덱스가 작은 로컬 개발: 1g면 충분
  - 데이터가 수백만 건 이상이거나, nori 같은 한국어 분석기를 많이 쓸 때: 2g
- **Docker Desktop 메모리 할당량** (Settings > Resources)
  - DB를 모두 띄우면 대략 ES 1.5g(힙 1g + 오버헤드), MySQL 0.5g, Postgres와 Redis 수백 MB 정도를 씀
  - 할당량이 4GB 이상이면 여유 있음

## 비밀번호 처리

주석으로 표시해 두고 쓸 때 바꾸는 방식에 맞춤. 다만 위치는 compose가 아니라 **`.env.example`** 추천

- compose 파일에 직접 쓰면, 비밀번호를 바꾼 뒤 그대로 커밋해서 public 저장소에 올라갈 위험이 있음
- `.env.example`에 `# 사용 시 변경` 주석과 자리표시자를 넣어 둠. 쓸 때는 `cp .env.example .env`로 복사해서 수정. `.env`는 gitignore 대상이라 커밋되지 않음

## 확인할 점

- plan1의 `docker inspect` 결과에 있는 비밀번호는 여전히 평문. 마스킹 여부 결정 필요
- ES 버전을 8.12.2로 유지할지, 8.19.23으로 올릴지 결정 필요

---

# 비밀번호 마스킹, ES 8.19.23, 보안 모드

> plan1 비번 마스킹해주고, es 버전 8.19.23으로 해줘. 그리고 보안모드 켜주라

## 답변

- plan1의 `docker inspect` 결과에 있던 `POSTGRES_PASSWORD`, `ELASTIC_PASSWORD`를 `****`로 마스킹함
- ES는 8.19.23에 보안 모드를 켜는 걸로 정리

## ES 보안 모드 설정

로컬 단일 노드에 맞춰 **인증(아이디/비밀번호)만 켜고 TLS는 끄는** 구성 추천

```yaml
environment:
  discovery.type: single-node
  xpack.security.enabled: "true"
  # 로컬 단일 노드라 HTTPS, 노드 간 TLS는 쓰지 않는다. 인증만 적용한다.
  xpack.security.http.ssl.enabled: "false"
  xpack.security.transport.ssl.enabled: "false"
  # 최초 기동 시 elastic 계정 비밀번호로 설정된다.
  ELASTIC_PASSWORD: ${ELASTIC_PASSWORD}
  ES_JAVA_OPTS: -Xms${ES_HEAP} -Xmx${ES_HEAP}
```

- **TLS를 끄는 이유**: TLS까지 켜면 인증서를 만들고 클라이언트마다 CA를 등록해야 함. `127.0.0.1`에만 열려 있는 로컬 환경에서는 그만큼의 이득이 없음
- **`ELASTIC_PASSWORD`를 다시 씀**: 앞에서는 보안이 꺼져 있어 빼기로 했지만, 이제 `elastic` 계정 비밀번호로 쓰임. `.env.example`에 자리표시자로 둠
- **기존 데이터에서도 동작함**: 지금까지 보안이 꺼져 있어서 계정 정보가 없었으므로, 첫 기동 때 `ELASTIC_PASSWORD`로 비밀번호가 설정됨
- **클라이언트 설정 변경 필요**: 이제 인증이 필요함
  - Spring 등 앱: `spring.elasticsearch.username=elastic`, `password=...`
  - curl: `curl -u elastic:<비밀번호> localhost:9200`

## 8.19.23 업그레이드 주의점

- **되돌릴 수 없음**: 8.12 데이터는 8.19가 읽고 변환하지만, 한 번 8.19로 띄우면 8.12로 돌아갈 수 없음
- **그래서 이전할 때는 이동이 아니라 복사로 바꿈**
  1. 기존 `~/DataGripProjects/DockerMount/elasticsearch/data`를 새 경로로 `cp -R`로 복사
  2. 8.19로 정상 기동되는지 확인
  3. 확인한 뒤에 기존 디렉토리 삭제
- Postgres도 같은 방식(복사 → 확인 → 기존 삭제)으로 진행

---
