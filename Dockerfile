FROM ruby:2.7.1 
ARG RAILS_KEY 
RUN bundle config --global frozen 1 

WORKDIR /usr/src/app 

# 1. МАГІЧНИЙ ФІКС: Міняємо мертві лінки Debian на архівні
RUN sed -i s/deb.debian.org/archive.debian.org/g /etc/apt/sources.list && \
   sed -i 's|security.debian.org|archive.debian.org/|g' /etc/apt/sources.list && \
   sed -i '/-updates/d' /etc/apt/sources.list

# 2. Тепер apt update не впаде! Оновлюємо та ставимо базові утиліти
RUN apt-get update -y && apt-get install -y curl build-essential libpq-dev

# 3. Ставимо Node.js 16
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - 
RUN apt-get install -y nodejs 

# 4. Ставимо Yarn через npm (це ніколи не падає)
RUN npm install --global yarn

# 5. Твої стандартні кроки збирання
# Явно вказуємо yarn.lock (зірочка на кінці, щоб не впало, якщо файлу раптом немає локально)
COPY package.json yarn.lock* ./ 
RUN yarn install

COPY Gemfile Gemfile.lock ./ 
RUN bundle install 

COPY . . 

# Додали python3 в кінець
RUN apt-get update -y && apt-get install -y curl build-essential libpq-dev python3

# Warning про ARG буде висіти, але білд пройде
# Додаємо NODE_ENV та SECRET_KEY_BASE (інколи webpacker цього вимагає)
RUN RAILS_ENV=production \
   NODE_ENV=production \
   RAILS_MASTER_KEY=$RAILS_KEY \
   SECRET_KEY_BASE=dummy_variable_for_compile \
   bundle exec rails webpacker:compile
CMD ["rails", "s", "-b", "0.0.0.0"]