# GNU Lesser General Public License v3.0 only
# Copyright (C) 2020 Artefact
# licence-information@artefact.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
FROM python:3.7

WORKDIR /mlflow/

RUN mkdir -p /mlflow/ \
  && apt-get update \
  && apt-get -y install --no-install-recommends apt-transport-https \
  ca-certificates gnupg default-libmysqlclient-dev libpq-dev build-essential curl

RUN curl -sSL https://sdk.cloud.google.com | bash
ENV PATH $PATH:/root/google-cloud-sdk/bin
RUN gcloud components install beta -q

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY run_tracking.sh .
RUN chmod +x run_tracking.sh

CMD /mlflow/run_tracking.sh