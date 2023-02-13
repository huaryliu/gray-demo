# <CHARTNAME>

## 准备

### 工具

使用前请确保本级已完成kubectl(v1.18.0+)和helm(v3.2+)命令行工具的安装。并正确配置Kubenetes本地客户端连接。

kubectl安装请参考：https://kubernetes.io/zh/docs/tasks/tools/

helm安装请参考：https://helm.sh/docs/intro/install/

### 容器镜像

如果安装目标集群无法访问公网获取镜像，请向公司镜像仓库管理员提前索取镜像提前Load到私有化容器镜像仓库或集群Worker节点上。

如果安装目标集群可以访问公网获取镜像，请检查安装目标命名空间下是否存已有名为`csp.docker.iec.io`的镜像仓库密钥，如还未创建可以通过下面的命令在目标集群创建公司镜像仓库管理员的密钥：

```shell
kubectl -n [目标命名空间] create secret docker-registry csp.docker.iec.io --docker-server=csp.docker.iec.io --docker-username=xxxxxx --docker-password=xxxxxxxxxxxxxx
```

具体密钥信息请向公司镜像仓库管理员索取。

### 域名和证书

强烈建议通过域名 + HTTPS（TLS）的方式对外暴露服务。对于通行证服务需要申请专用的客户二级域名，例如：`<CHARTNAME>.mycompany.com`。

TLS/SSL证书配置按照网关类型不同有微小的差别，本Chart包支持Ingress Nginx和Istio VirtualService两种类型的网关路由策略。

对于Ingress Nginx类型的网关，可以通过下面的命令在应用安装命名空间下创建TLS密钥以存储客户提供的SSL证书。密钥的名称建议使用`tls-cert-`+`倒置域名`的形式。对于通了域名可以使用`wildcard`代替`*`通配符。例如客户提供的域名证书适用于域名：`*.mycompany.com`，对应可以创建名为`tls-cert-com-mycompany-wildcard`的TLS密钥存储所提供的SSL证书：

```shell
kubectl -n [目标命名空间] create secret tls tls-cert-com-mycompany-wildcard --cert=[证书公钥文件的路径] --key=[证书私钥文件的路径]
```

对于Istio类型的网关，除了需要通过上述命令创建TLS密钥外还需要提前初始化好对应域名的Gateway。例如对于上述域名`*.mycompany.com`可以在`istio-system`命名空间下通过如下命令创建Gateway：

```shell
cat << EOF | kubectl -n istio-system create -f -
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: gw-com-mycompany-wildcard
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - '*.mycompany.com'
    port:
      name: http
      number: 80
      protocol: HTTP
    tls:
      httpsRedirect: true
  - hosts:
    - '*.mycompany.com'
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      cipherSuites:
      - ECDHE-ECDSA-AES128-GCM-SHA256
      - ECDHE-RSA-AES128-GCM-SHA256
      - ECDHE-ECDSA-AES256-GCM-SHA384
      - ECDHE-RSA-AES256-GCM-SHA384
      - ECDHE-ECDSA-CHACHA20-POLY1305
      - ECDHE-RSA-CHACHA20-POLY1305
      - DHE-RSA-AES128-GCM-SHA256
      - DHE-RSA-AES256-GCM-SHA384
      credentialName: tls-cert-com-mycompany-wildcard
      minProtocolVersion: TLSV1_2
      mode: SIMPLE
EOF
```

## 安装

可以使用浪潮Helm Charts仓库中的Chart包安装，也可以使用本地的Chart包进行安装。

使用如下命令可以通过本地Chart包完成安装：

```shell
helm install -n [目标命名空间] <CHARTNAME>-stable ./<CHARTNAME>-0.1.0.tgz
```

使用如下命令可以通浪潮Helm Charts仓库中的Chart包完成安装：

```shell
helm install -n [目标命名空间] <CHARTNAME>-stable helm-csp/<CHARTNAME> --version 0.1.0
```

如需指定域名及证书信息，可以通过下面命令在Ingress Nginx或Istio网关中指定相应配置：

- **安装时在Ingress Nginx网关中设置域名及证书**

```shell
helm install -n [目标命名空间] <CHARTNAME>-stable ./<CHARTNAME>-0.1.0.tgz \
--set gateway.enabled=true \
--set gateway.type=ingress-nginx \
--set "gateway.hosts={<CHARTNAME>.mycompany.com}" \
--set gateway.ingress.tlsSecretName=tls-cert-com-mycompany-wildcard
```

- **安装时在Istio网关中设置域名及证书**

```shell
helm install -n [目标命名空间] <CHARTNAME>-stable ./<CHARTNAME>-0.1.0.tgz \
--set gateway.enabled=true \
--set gateway.type=istio-virtual-service \
--set "gateway.hosts={<CHARTNAME>.mycompany.com}" \
--set "gateway.istioGateways={istio-system/gw-com-mycompany-wildcard}"
```

除了域名及证书之外，你还可以通过安装参数提供必要的初始化信息，数据库将自动完成初始化。免去了时候手工初始化的繁琐步骤，例如：

- 在Ingress Nginx环境中使用下面的命令完成自动化安装：

```shell
helm install -n [目标命名空间] <CHARTNAME>-stable ./<CHARTNAME>-0.1.0.tgz \
--set gateway.enabled=true \
--set gateway.type=ingress-nginx \
--set "gateway.hosts={<CHARTNAME>.mycompany.com}" \
--set gateway.ingress.tlsSecretName=tls-cert-com-mycompany-wildcard \
--set setup.enabled=true \
--set setup.params.tenant.id=客户的租户ID \
--set setup.params.tenant.code=客户的租户代号 \
--set setup.params.tenant.name=客户的租户名称
```

- 在Istio环境中使用下面的命令完成自动化安装：

```shell
helm install -n [目标命名空间] <CHARTNAME>-stable ./<CHARTNAME>-0.1.0.tgz \
--set gateway.enabled=true \
--set gateway.type=istio-virtual-service \
--set "gateway.hosts={<CHARTNAME>.mycompany.com}" \
--set "gateway.istioGateways={istio-system/gw-com-mycompany-wildcard}" \
--set setup.enabled=true \
--set setup.params.tenant.id=客户的租户ID \
--set setup.params.tenant.code=客户的租户代号 \
--set setup.params.tenant.name=客户的租户名称
```

具体的初始化信息可以从开发人员处获得。

> **⚠️特别注意：**
>
> 由于初始化任务仅会再首次安装时执行，如果首次安装时没有指定初始化信息，之后不可再补充指定，即使通过`helm upgrade`命令补充这些初始化参数也不会使数据库自动初始化。

如果安装时忘记指定对应参数，或者需要在后期修改这些参数，可以通过`helm upgrade`命令更新这些参数，需要注意的是每次更新都必须完整提供之前已经提供的所有参数设置，否则未提供的参数将变为默认值：


```shell
helm upgrade -n [目标命名空间] <CHARTNAME>-stable ./<CHARTNAME>-0.1.0.tgz \
--set gateway.enabled=true \
--set gateway.type=ingress-nginx \
--set "gateway.hosts={<CHARTNAME>.mycompany.com}" \
--set gateway.ingress.tlsSecretName=tls-cert-com-mycompany-wildcard
```

安装成功后通过kubectl命令查看pod状态，待所有READY的分子和分母值一致即为安装完成：

```shell
kubectl -n [目标命名空间] get pod
NAME																					READY STATUS		RESTARTS	AGE
<CHARTNAME>-stable-api-84£6bd755-s2hfc				1/1		Running		0					1m
<CHARTNAME>-stable-web-84f6bd755-vr411				1/1   Running		0					1m
<CHARTNAME>-stable-mam-79b4d4d87-r4cgs				1/1   Running		0					1m
<CHARTNAME>-stable-mam-79b4d4d87-rrztd				1/1   Running		0					1m
<CHARTNAME>-stable-mcm-5cb69f8f59-krdrj				1/1		Running		0					1m
<CHARTNAME>-stable-mcm-5cb6918f59-qmbgx				1/1 	Running		0					1m
<CHARTNAME>-stable-nsys-698fbfc47-2fwbd				1/1 	Running		0					1m
<CHARTNAME>-stable-nsys-698fbfc47-2bg86				1/1		Running		0					1m
<CHARTNAME>-stable-sys-659987b66d-rbfre				1/1 	Running		0					1m
<CHARTNAME>-stable-sys-659987666d-t8gd5				1/1 	Running		0					1m
```

过程中部分Pod的RESTARTS列的显示有重启属于正常现象。如果某个Pod一致无法READY，可以通过`kubectl describe [具体Pod Name]`来了解更多信息。

## 初始化

推荐使用前面的安装参数直接自动完成初始化，如遇到特殊情况必须手动完成初始化工作，可以遵循下面的步骤：

### 初始化数据库

通过下面的命令可以从本地端口`:3306`临时连接<CHARTNAME>数据库:

```shell
kubectl -n [目标命名空间] port-forward service/<CHARTNAME>-stable-msyql 3306:3306
```

数据库的用户名为`<CHARTNAME>`，密码需要从Kubernetes Secret中查找。之后通过数据库连接工具连接`localhost:3306`即可访问<CHARTNAME>数据库。

通过下面的脚本完成数据初始化，，请将`企业ID`、`企业CODE`、`企业名称`3个参数批量查找替换为项目对应的参数信息。

```sql
# 初始化数据库
CREATE TABLE IF NOT EXISTS test (
  id varchar(50) NOT NULL COMMENT '主键，租户的唯一标识',
  name varchar(200) DEFAULT NULL COMMENT '租户的名称',
);
```



## 集成

### 通行证集成

云+企业移动管理平台需要通过通行证完成身份认证，请通过通行证管理界面注册云+即时通信服务，之后将获得的Client ID和Client Secret写入对应的Kubernetes Secret。这一步可以通过Heimdall Web控制台或者CLI命令完成。

找到passport结尾的secret，如果使用CLI方式可以通过下面的命令修改secret中的配置：

```shell
kubectl edit secret <CHARTNAME>-stable-passport
```

编辑Secret中的对应内容完成与通行证的集成。

```yaml
data:
  # Client ID
  passport-client-id: MTE0ZjZmNTAtODViZi00YTM3LWI3OWUtMjJiMDJmZmVlNzlh
  # Client Secret
  passport-client-secret: NDI2YWUxZTktZGZiZi00YjU5LTg5ODItOTY5N2U0N2Y5ODc4
```

> **⚠️特别注意：**
>
> 修改密钥后需要收缩各个模块副本数量到0再重新扩容到项目所需的副本数量，通过这种方式实现服务重启，使得相关配置生效。这一步可以通过Heimdall Web控制台或者CLI命令完成，如果选用CLI模式，可以参考下面的命令：
>
> ```shell
> kubectl scale deployment <CHARTNAME>-stable-api --replicas=0
>
> kubectl scale deployment <CHARTNAME>-stable-api --replicas=2
> ```

## 信创支持

<CHARTNAME>可以运行在ARM64架构的信创集群环境，和DM信创数据库中。

安装时需要提前安装好DM数据库和信创Redis，并提前创建好外部数据库和Redis的密钥信息。

```shell
kubectl -n [目标命名空间] create secret generic <CHARTNAME>-stable-external-dm --from-literal dm-user-password=DM数据库密码
kubectl -n [目标命名空间] create secret generic <CHARTNAME>-stable-external-redis --from-literal redis-password=Redis密码
```

通过下面的命令完成<CHARTNAME>安装：

```shell
helm install -n [目标命名空间] <CHARTNAME>-stable helm-csp/<CHARTNAME> --version 0.1.0 \
--set postgresql.enabled=false \
--set mysql.enabled=false \
--set redis.enabled=false \
--set postgresql.enabled=false \
--set external.mysql.dbms=dm \
--set external.mysql.host=DM数据库地址 \
--set external.mysql.port=DM数据库端口 \
--set external.mysql.username=DM数据库用户名 \
--set external.mysql.secretName=<CHARTNAME>-stable-external-dm \
--set external.mysql.secretKey=dm-user-password \
--set external.redis.host=Redis连接地址 \
--set external.redis.port=Redis连接端口 \
--set external.redis.secretName=<CHARTNAME>-stable-external-redis \
--set external.redis.secretKey=redis-password
```

