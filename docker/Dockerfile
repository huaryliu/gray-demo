# 基于java镜像创建新镜像
FROM adoptopenjdk/openjdk11
# 作者
MAINTAINER liujhtr@inspur.com
# 将jar包添加到容器中
RUN mkdir /app
ADD  ./gray-demo-0.0.1-SNAPSHOT.jar /app/gray-demo-0.0.1-SNAPSHOT.jar
# 运行jar包
ENTRYPOINT ["java","-jar","/app/gray-demo-0.0.1-SNAPSHOT.jar"]