FROM python:3
ENV PYTHONUNBUFFERED 1
WORKDIR /mysite
ADD requirements.txt /mysite/
RUN pip install -r requirements.txt
ADD . /mysite/
