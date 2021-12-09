---
name: Hackathon Bug
about: Template for filing bugs during a hackathon session
title: "[BUG] ..."
labels: bug, hackathon
assignees: eriknelson

---

**What version of crane are you running, and what are your clutsters+platform**

To get the crane/crane-lib version:

`${RUNTIME:-docker} run --rm -it ${RUNNER_IMAGE} version`

Example:

```
$ docker run --rm -it quay.io/djzager/crane-runner:$(git rev-parse --short HEAD) version
crane:
  Version: v0.0.3
crane-lib:
  Version: v0.0.5
```

**What date were you attending the hackathon?**

**What scenario were you running when you encountered the issue?**

**What did you expect to happen?**

**What actually happened?**

**Please include any relevant logs or errors**
