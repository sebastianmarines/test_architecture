from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import ECS, EC2
from diagrams.aws.database import RDS
from diagrams.aws.management import SSM
from diagrams.aws.network import ALB, VPC, PrivateSubnet, PublicSubnet, NATGateway
from diagrams.aws.security import IAM, IdentityAndAccessManagementIamTemporarySecurityCredential, SecretsManager
from diagrams.generic.device import Mobile

with Diagram("AWS Architecture", show=False):
    ssm_patch_manager = SSM("Patch Manager")
    ssm_session_manager = SSM("Session Manager")

    with Cluster("VPC"):
        with Cluster("Private Subnets"):
            ecs = ECS("Replica 1")
            bastion_host = EC2("Bastion Host")
        with Cluster("DB Subnets"):
            db_group = [RDS("MySQL"), RDS("MySQL Standby")]
        with Cluster("Public Subnets"):
            nat = NATGateway("NAT Gateway")
            alb = ALB("ALB")

    ssm_patch_manager >> Edge(color="firebrick", style="dashed")>> [ecs, bastion_host]
    ecs >> Edge(label="", color="black", style="bold") >> IdentityAndAccessManagementIamTemporarySecurityCredential("IAM temporary credentials") >> Edge(label="", color="black", style="bold") >> db_group[0]
    db_group[0] >> Edge(label="Synchronous replication") >> db_group[1]

    SecretsManager("Secrets Manager") - Edge(label="", color="black", style="bold") - db_group[0]

    Mobile("Mobile App") >> Edge(label="HTTPS", color="black", style="bold") >> alb >> Edge(label="", color="black", style="bold") >> ecs
    nat << Edge(color="purple", style="dotted") << [ecs, bastion_host]
    ssm_session_manager >> bastion_host