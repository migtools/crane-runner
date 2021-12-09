---
name: Bug Report
about: Generic bug report template
title: "[BUG] ..."
labels: bug

---

**What version of crane-runner are you using (git hash, image hash, image tag?), and what are your clutsters+platform**

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

**What did you expect to happen?**

**What actually happened?**

**Please include any relevant logs or errors**
