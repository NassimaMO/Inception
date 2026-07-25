NAME = inception

VOLUMES = /home/nnassiri/data

DOCKER_COMPOSE_PATH = srcs/docker-compose.yml

all: $(NAME)

$(NAME):
	mkdir -p /home/nnassiri/data/wp /home/nnassiri/data/db
	docker compose -f ${DOCKER_COMPOSE_PATH} build
	docker compose -f ${DOCKER_COMPOSE_PATH} up -d

state:
	docker compose -f ${DOCKER_COMPOSE_PATH} ps

network:
	docker network ls
	docker network inspect inception

volumes:
	docker volume ls

clean:
	docker compose -f ${DOCKER_COMPOSE_PATH} down

fclean: clean
	docker system prune -af --volumes
	sudo rm -rf ${VOLUMES}

re: fclean all

.PHONY: all clean fclean re state network volumes
