package pl.mfalkowski.NodeMCUtests;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;
import org.springframework.util.MultiValueMap;
import org.springframework.web.reactive.function.server.HandlerFunction;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Mono;
import reactor.util.Logger;
import reactor.util.Loggers;

import java.net.URI;
import java.util.Objects;

import static com.fasterxml.jackson.annotation.JsonAutoDetect.Visibility.NON_PRIVATE;
import static com.fasterxml.jackson.annotation.PropertyAccessor.FIELD;
import static org.springframework.web.reactive.function.server.RequestPredicates.GET;
import static org.springframework.web.reactive.function.server.RequestPredicates.POST;
import static org.springframework.web.reactive.function.server.RouterFunctions.route;

@SpringBootApplication
public class NodeMcuTestsApplication {

	private Logger logger = Loggers.getLogger(NodeMcuTestsApplication.class);
	private State state = new State();

    static class State {
	    String ssid;
	    String password;
	    String status;
    }

    static class Status {
        Wifi wifi;

        static class Wifi {
            String ssid;
            String status;
        }
    }

	public static void main(String[] args) {
		SpringApplication.run(NodeMcuTestsApplication.class, args);
	}

	private HandlerFunction<ServerResponse> statusHandler =
        request ->
            ServerResponse.ok().body(
                Mono.just(new Status())
                    .doOnNext(s -> s.wifi = new Status.Wifi())
                    .doOnNext(s -> s.wifi.status = state.status)
                    .doOnNext(s -> s.wifi.ssid = state.ssid),
                Status.class
            );


	private HandlerFunction<ServerResponse> connectHandler =
		request ->
			request.bodyToMono(new ParameterizedTypeReference<MultiValueMap<String, String>>() {})
                .flatMap(body ->
                    Mono.just(body.getFirst("ssid"))
                        .filter(Objects::nonNull)
                        .doOnNext(s -> logger.info("SSID: {}", s))
                        .doOnNext(s -> state.ssid = s)
                        .switchIfEmpty(Mono.fromRunnable(() -> logger.info("No ssid in request!")))
                        .then(Mono.just(body.getFirst("password")))
                        .filter(Objects::nonNull)
                        .doOnNext(p -> logger.info("password: {}", p))
                        .doOnNext(p -> state.password = p)
                        .switchIfEmpty(Mono.fromRunnable(() -> logger.info("No password in request!")))
                )
                .then(ServerResponse.seeOther(URI.create("/connecting")).build());


    @Bean
    RouterFunction<ServerResponse> routes()  {
		return route(GET("/status"), statusHandler)
			.and(
				route(GET("/dupa"), request -> ServerResponse.ok().render("dupa"))
			)
			.and(
				route(GET("/"), request -> ServerResponse.ok().render("root"))
			)
            .and(route(GET("/connecting"), request -> ServerResponse.ok().render("connecting")))
			.and(route(POST("/connect"), connectHandler));
    }

    @Bean
	ObjectMapper objectMapper(Jackson2ObjectMapperBuilder builder) {
		return builder.build()
			.setVisibility(FIELD, NON_PRIVATE);
	}
}
