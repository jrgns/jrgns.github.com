export interface Talk {
  title: string;
  event: string;
  url: string;
}

export const talks: Talk[] = [
  { title: "U2 should have used Elasticsearch", event: "DUG", url: "/talks/U2_should_have_used_Elasticsearch.pdf" },
  { title: "Moar logs! Logging on Linux using the ELK Stack", event: "JLUG", url: "/talks/Moar_Logs.pdf" },
  { title: "A gentle introduction into Elasticsearch", event: "Elasticsearch SA Meetup", url: "/talks/Gentle_intro_to_Elasticsearch.pdf" },
  { title: "Everything's Connected: Hacking the interwebs with Logstash", event: "Jozi.rb Meetup", url: "/talks/logstash-jozi-rb" },
  { title: "Leveraging the ELK stack to ensure API uptime", event: "Elasticsearch SA Meetup", url: "/talks/tutuka-elk" },
  { title: "Everything's Connected: Hacking the interwebs with Logstash", event: "Rubyfuza 2015 — Lightning Talk", url: "/talks/logstash-hacking-the-interwebs" },
  { title: "How CoffeeScript Improved My JavaScript Skills", event: "JSinSA 2014", url: "/talks/learning-from-coffeescript" },
  { title: "PHP — The slums of the programming world?", event: "Tech 4 Africa 2013", url: "/talks/phpslums/" },
  { title: "Application Development with Elasticsearch", event: "Elasticsearch SA Meetup", url: "/talks/Application Development with Elasticsearch.pdf" },
  { title: "Elasticsearch Health Check", event: "Elasticsearch SA Meetup", url: "/talks/Elasticsearch_Health_Check.pdf" },
];
